# Cribl Module - Cribl Stream (Linux) and Cribl Edge (Windows)
# Leader/worker pair: Edge connects to Stream's private IP on port 4200

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
}

# Cribl Stream user_data — install via RPM, configure as leader
locals {
  cribl_stream_user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eo pipefail
    yum update -y

    # Install SSM agent (should be pre-installed on Amazon Linux 2)
    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent

    # Create cribl user
    useradd -r -m -s /bin/bash cribl

    # Download and install Cribl Stream via RPM
    cd /tmp
    CRIBL_RPM="cribl-${var.cribl_version}-${var.cribl_build}-linux-x64.rpm"
    CRIBL_URL="https://cdn.cribl.io/dl/${var.cribl_version}/$CRIBL_RPM"
    curl -fsSL -o "$CRIBL_RPM" "$CRIBL_URL"
    rpm -ivh "$CRIBL_RPM"
    chown -R cribl:cribl /opt/cribl

    # Configure as leader (single-instance mode with API on 4200)
    sudo -u cribl /opt/cribl/bin/cribl mode-master

    # Enable boot-start via systemd and start
    /opt/cribl/bin/cribl boot-start enable -m systemd -u cribl
    systemctl start cribl
  EOF
  )
}

# Cribl Edge user_data — Windows PowerShell, silent MSI install connecting to Stream leader
locals {
  cribl_edge_user_data = base64encode(<<-WINEOF
<powershell>
# Set Administrator password (auto-generated per-build)
$ErrorActionPreference = "Stop"
$adminPassword = ConvertTo-SecureString "${var.windows_admin_password}" -AsPlainText -Force
Get-LocalUser -Name "Administrator" | Set-LocalUser -Password $adminPassword

# Install Cribl Edge and connect to Stream leader
$criblVersion = "${var.cribl_version}"
$criblBuild = "${var.cribl_build}"
$streamIp = "${try(aws_instance.cribl_stream[0].private_ip, "")}"
$msiUrl = "https://cdn.cribl.io/dl/$criblVersion/cribl-edge-$criblVersion-$criblBuild-win64.msi"
$msiPath = "C:\Windows\Temp\cribl-edge.msi"

# Download MSI
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

# Install Cribl Edge in managed-edge mode connecting to Stream leader
Start-Process msiexec.exe -ArgumentList "/qn /i `"$msiPath`" CRIBL_LEADER=tcp://$($streamIp):4200" -Wait -NoNewWindow

# Start the service
Start-Service CriblEdge
</powershell>
  WINEOF
  )
}

# Cribl Stream Instance (Linux)
resource "aws_instance" "cribl_stream" {
  count = var.enable_cribl ? 1 : 0

  ami                         = var.linux_ami_id
  instance_type               = var.cribl_stream_instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_ids[0]
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.instance_profile_name

  user_data_base64 = local.cribl_stream_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.environment}-cribl-stream-root"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-cribl-stream"
    Role = "cribl-stream"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cribl Edge Instance (Windows Server 2022)
resource "aws_instance" "cribl_edge" {
  count = var.enable_cribl ? 1 : 0

  ami                         = var.windows_ami_id
  instance_type               = var.cribl_edge_instance_type
  key_name                    = var.key_pair_name
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_ids[0]
  associate_public_ip_address = var.associate_public_ip_address
  iam_instance_profile        = var.instance_profile_name

  user_data_base64 = local.cribl_edge_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = merge(local.common_tags, {
      Name = "${var.environment}-cribl-edge-root"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-cribl-edge"
    Role = "cribl-edge"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "cribl_stream" {
  count = var.enable_cribl ? 1 : 0

  name              = "/aws/ec2/${var.environment}-cribl-stream"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.environment}-cribl-stream-logs"
  })
}

resource "aws_cloudwatch_log_group" "cribl_edge" {
  count = var.enable_cribl ? 1 : 0

  name              = "/aws/ec2/${var.environment}-cribl-edge"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "${var.environment}-cribl-edge-logs"
  })
}
