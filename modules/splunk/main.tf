# Splunk Module - Splunk-specific instances and configuration
# Handles Splunk infrastructure deployment and configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Current AWS region (used in user_data for SSM parameter retrieval)
data "aws_region" "current" {}

# Local values for consistent tagging
locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
  # rate() requires singular "hour" for value 1, plural "hours" for all others
  lifecycle_schedule_unit = var.lifecycle_interval_hours == 1 ? "hour" : "hours"
}

# User data script for Splunk instance
locals {
  splunk_user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eo pipefail
    yum update -y

    # Install required packages
    yum install -y wget tar

    # Install SSM agent (should be pre-installed on Amazon Linux 2)
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Install CloudWatch agent
    yum install -y amazon-cloudwatch-agent

    # Create splunk user
    useradd -r -m -s /bin/bash splunk

    # Download and install Splunk
    cd /opt
    SPLUNK_PKG="splunk-${var.splunk_version}-${var.splunk_build}-Linux-aarch64.tgz"
    SPLUNK_BASE_URL="https://download.splunk.com/products/splunk/releases/${var.splunk_version}/linux"
    wget -O "$${SPLUNK_PKG}" "$${SPLUNK_BASE_URL}/$${SPLUNK_PKG}"
    wget -O "$${SPLUNK_PKG}.sha512" "$${SPLUNK_BASE_URL}/$${SPLUNK_PKG}.sha512"
    sha512sum -c "$${SPLUNK_PKG}.sha512" || { echo "ERROR: Splunk package checksum mismatch. Aborting." >&2; exit 1; }
    tar -xzf "$${SPLUNK_PKG}"
    chown -R splunk:splunk /opt/splunk

    # Configure SmartStore (S3 remote storage for warm/cold buckets)
    # Must run before first Splunk start so indexes are created with SmartStore enabled
    mkdir -p /opt/splunk/etc/system/local

    cat > /opt/splunk/etc/system/local/indexes.conf << 'INDEXES'
[volume:s3_store]
storageType = remote
path = s3://${var.smartstore_bucket_name}/smartstore

[default]
remotePath = volume:s3_store/$$_index_name
repFactor = 0
maxDataSize = auto
INDEXES

    cat > /opt/splunk/etc/system/local/server.conf << 'SERVER'
[cachemanager]
max_cache_size = 5120
eviction_policy = lru
SERVER

    chown -R splunk:splunk /opt/splunk/etc/system/local

    # Retrieve Splunk admin password from SSM Parameter Store (never stored in user_data)
    SPLUNK_PASSWORD=$$(aws ssm get-parameter \
      --name "${var.splunk_password_ssm_name}" \
      --with-decryption \
      --query 'Parameter.Value' \
      --output text \
      --region ${data.aws_region.current.id})

    if [ -z "$$SPLUNK_PASSWORD" ]; then
      echo "ERROR: Failed to retrieve Splunk password from SSM or password is empty. Aborting." >&2
      exit 1
    fi

    # Start Splunk and accept license
    sudo -u splunk /opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "$$SPLUNK_PASSWORD"
    unset SPLUNK_PASSWORD

    # Enable Splunk to start at boot
    /opt/splunk/bin/splunk enable boot-start -user splunk

    # Configure basic settings
    sudo -u splunk /opt/splunk/bin/splunk set web-port 8000
    sudo -u splunk /opt/splunk/bin/splunk restart
    %{if var.enable_auto_lifecycle}

    # Auto-lifecycle: schedule shutdown ${var.auto_shutdown_minutes} minutes after every boot.
    # cloud-init per-boot scripts run on every instance start (first boot and subsequent restarts).
    mkdir -p /var/lib/cloud/scripts/per-boot
    cat > /var/lib/cloud/scripts/per-boot/auto-shutdown.sh << 'SHUTDOWN'
#!/bin/bash
# Guard: only shut down if Splunk is installed (skip first-boot provisioning run).
if [ -f /opt/splunk/bin/splunk ]; then
  /sbin/shutdown -h +${var.auto_shutdown_minutes}
fi
SHUTDOWN
    chmod +x /var/lib/cloud/scripts/per-boot/auto-shutdown.sh
    %{endif}
  EOF
  )
}

# Splunk Instance
resource "aws_instance" "splunk" {
  ami                    = var.ami_id
  instance_type          = var.splunk_instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [var.splunk_security_group_id]
  subnet_id              = var.private_subnet_ids[0] # Use first private subnet
  iam_instance_profile   = var.splunk_instance_profile_name

  user_data_base64 = local.splunk_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = var.splunk_root_volume_size
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.environment}-splunk-root"
    })
  }

  # Additional EBS volume for Splunk data
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = var.splunk_data_volume_size
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.environment}-splunk-data"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-instance"
    Role = "splunk"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for Splunk instance
resource "aws_cloudwatch_log_group" "splunk" {
  name              = "/aws/ec2/${var.environment}-splunk"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-logs"
  })
}

# CloudWatch Log Group for Splunk application logs
resource "aws_cloudwatch_log_group" "splunk_app" {
  name              = "/splunk/${var.environment}"
  retention_in_days = 90

  tags = merge(local.common_tags, {
    Name = "${var.environment}-splunk-app-logs"
  })
}

# Auto-lifecycle: EventBridge Scheduler starts Splunk on a recurring schedule.
# Per-boot script (in user_data above) shuts it down after auto_shutdown_minutes.
# All resources below are only created when enable_auto_lifecycle = true.

resource "aws_iam_role" "lifecycle_scheduler" {
  count = var.enable_auto_lifecycle ? 1 : 0

  name = "${var.environment}-splunk-lifecycle-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "lifecycle_scheduler" {
  count = var.enable_auto_lifecycle ? 1 : 0

  name = "${var.environment}-splunk-lifecycle-scheduler"
  role = aws_iam_role.lifecycle_scheduler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:StartInstances"]
      Resource = "arn:aws:ec2:*:*:instance/${aws_instance.splunk.id}"
    }]
  })
}

resource "aws_scheduler_schedule" "splunk_start" {
  count = var.enable_auto_lifecycle ? 1 : 0

  name        = "${var.environment}-splunk-start"
  description = "Start Splunk every ${var.lifecycle_interval_hours} hours for data indexing"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(${var.lifecycle_interval_hours} ${local.lifecycle_schedule_unit})"

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.lifecycle_scheduler[0].arn

    input = jsonencode({
      InstanceIds = [aws_instance.splunk.id]
    })
  }
}
