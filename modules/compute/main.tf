# Unified compute module for both EC2 instances and ECS containers
# Supports various compute workloads with proper tagging and security

variable "environment" {
  description = "Environment name (dev/stg/prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where compute resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for compute deployment"
  type        = list(string)
}

variable "ec2_instances" {
  description = "Configuration for EC2 instances"
  type = map(object({
    ami_id        = string
    instance_type = string
    disk_size     = number
    count         = number
    subnet_type   = string # "public" or "private"
    user_data     = string
    security_groups = list(string)
  }))
  default = {}
}

variable "ecs_enabled" {
  description = "Enable ECS cluster for container workloads"
  type        = bool
  default     = false
}

variable "ecs_services" {
  description = "Configuration for ECS services"
  type = map(object({
    image         = string
    cpu           = number
    memory        = number
    desired_count = number
    port          = number
  }))
  default = {}
}

variable "auto_scaling_enabled" {
  description = "Enable auto scaling for EC2 instances"
  type        = bool
  default     = false
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "splunk-aws"
    ManagedBy   = "terraform"
  }
}

# Default security group for compute resources
resource "aws_security_group" "compute_default" {
  name_prefix = "${var.environment}-compute-"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # HTTP/HTTPS for web services
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-compute-default-sg"
  })
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Attach basic policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EC2 Instances
resource "aws_instance" "ec2_instances" {
  for_each = var.ec2_instances

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = var.subnet_ids[0] # Can be enhanced for multi-AZ
  vpc_security_group_ids = concat([aws_security_group.compute_default.id], each.value.security_groups)
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_type = "gp3"
    volume_size = each.value.disk_size
    encrypted   = true
  }

  user_data = base64encode(each.value.user_data)

  tags = merge(local.common_tags, {
    Name        = "${var.environment}-${each.key}"
    WorkloadType = "ec2"
  })
}

# ECS Cluster (optional)
resource "aws_ecs_cluster" "main" {
  count = var.ecs_enabled ? 1 : 0
  name  = "${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-ecs-cluster"
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_execution_role" {
  count = var.ecs_enabled ? 1 : 0
  name  = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  count      = var.ecs_enabled ? 1 : 0
  role       = aws_iam_role.ecs_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Definitions and Services
resource "aws_ecs_task_definition" "services" {
  for_each = var.ecs_enabled ? var.ecs_services : {}

  family                   = "${var.environment}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.ecs_execution_role[0].arn

  container_definitions = jsonencode([
    {
      name  = each.key
      image = each.value.image
      portMappings = [
        {
          containerPort = each.value.port
          hostPort      = each.value.port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.environment}-${each.key}"
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}-task"
  })
}

resource "aws_ecs_service" "services" {
  for_each = var.ecs_enabled ? var.ecs_services : {}

  name            = "${var.environment}-${each.key}"
  cluster         = aws_ecs_cluster.main[0].id
  task_definition = aws_ecs_task_definition.services[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.compute_default.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}-service"
  })
}

# CloudWatch Log Groups for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  for_each = var.ecs_enabled ? var.ecs_services : {}

  name              = "/ecs/${var.environment}-${each.key}"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${var.environment}-${each.key}-logs"
  })
}

# Data sources
data "aws_region" "current" {}
