# Terraform Modules for Splunk AWS Infrastructure

This directory contains consolidated, reusable Terraform modules for deploying Splunk infrastructure on AWS. The modules follow DRY principles and AWS best practices.

## 📁 Module Structure

### Core Infrastructure Modules

#### 🌐 `network/`
**Comprehensive networking foundation**
- VPC with public/private subnets across multiple AZs
- Internet Gateway and NAT Gateways for secure connectivity
- Route tables and security group foundations
- Configurable CIDR blocks and availability zones

**Key Features:**
- Multi-AZ deployment for high availability
- Separate public/private subnet tiers
- Encrypted traffic and secure routing
- Cost-optimized NAT Gateway deployment

#### 🔒 `security/`
**Unified security and compliance management**
- IAM roles, policies, and access management
- AWS Secrets Manager for sensitive data
- KMS encryption keys with automatic rotation
- GuardDuty threat detection
- CloudTrail audit logging with encrypted S3 storage
- Custom security groups with granular rules

**Key Features:**
- Least privilege access principles
- Automated threat detection and response
- Comprehensive audit logging
- Secrets encryption and rotation
- Compliance-ready configurations

#### 💻 `compute/`
**Flexible compute resources for various workloads**
- EC2 instances with auto-scaling capabilities
- ECS Fargate containers for microservices
- Load balancers and health checks
- Instance profiles with appropriate IAM permissions
- CloudWatch monitoring integration

**Key Features:**
- Support for both VMs and containers
- Auto-scaling based on demand
- Comprehensive monitoring and logging
- Secure instance configurations
- Cost optimization features

### Application-Specific Modules

#### 🔍 `splunk/`
**Complete Splunk enterprise deployment**
- Indexers with clustering support
- Search heads for distributed searching
- Universal Forwarders for data collection
- Security groups optimized for Splunk communication
- Automated configuration via user data scripts

**Key Features:**
- Scalable indexer clusters
- High availability search head configuration
- Automated Splunk installation and configuration
- Support for distributed deployments
- Integration with AWS services

#### 📊 `monitoring/`
**Comprehensive monitoring and logging**
- Centralized syslog servers for log aggregation
- CloudWatch dashboards and custom metrics
- Log retention and rotation policies
- SNS notifications for critical alerts
- Integration with Splunk for advanced analytics

**Key Features:**
- Multi-protocol log collection (TCP/UDP)
- Real-time monitoring and alerting
- Log forwarding to Splunk indexers
- Cost-effective log retention
- Automated log rotation and cleanup

## 🚀 Usage Examples

### Basic Infrastructure Deployment

```hcl
# Network foundation
module "network" {
  source = "./modules/network"
  
  environment             = "dev"
  vpc_cidr               = "10.0.0.0/16"
  availability_zones     = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs    = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs   = ["10.0.10.0/24", "10.0.20.0/24"]
}

# Security foundation
module "security" {
  source = "./modules/security"
  
  environment    = "dev"
  vpc_id         = module.network.vpc_id
  enable_guardduty = true
  enable_cloudtrail = true
  
  secrets = {
    splunk_admin = {
      description = "Splunk admin credentials"
      secret_data = {
        username = "admin"
        password = "SecurePassword123!"
      }
    }
  }
}
```

### Splunk Deployment

```hcl
module "splunk" {
  source = "./modules/splunk"
  
  environment          = "dev"  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  splunk_admin_password = "SecurePassword123!"
  
  indexer_config = {
    count         = 3
    instance_type = "m5.large"
    disk_size     = 100
  }
  
  search_head_config = {
    count         = 2
    instance_type = "m5.medium"
    disk_size     = 50
  }
  
  enable_clustering = true
}
```

### Monitoring Setup

```hcl
module "monitoring" {
  source = "./modules/monitoring"
  
  environment         = "dev"  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  splunk_indexer_ips = module.splunk.indexer_instances.private_ips
  
  syslog_config = {
    enabled       = true
    instance_type = "t3.medium"
    count         = 2
    disk_size     = 50
    ami_id        = "ami-0c02fb55956c7d316"
  }
  
  log_sources = {
    application = {
      log_group_name = "/aws/application/logs"
      filter_pattern = "ERROR"
      retention_days = 14
    }
  }
}
```

## 🔧 Module Dependencies

```mermaid
graph TD    A[network] --> B[security]
    A --> C[compute]
    A --> D[splunk]
    A --> E[monitoring]
    B --> C
    B --> D
    B --> E
    D --> E
```

## 📝 Best Practices Implemented

### 🔐 Security
- ✅ Encryption at rest and in transit
- ✅ Least privilege IAM policies
- ✅ Network segmentation with security groups
- ✅ Automated secret rotation
- ✅ Comprehensive audit logging

### 🏗️ Infrastructure
- ✅ Multi-AZ deployments for high availability
- ✅ Auto-scaling for demand management
- ✅ Resource tagging for cost management
- ✅ Backup and disaster recovery considerations

### 📊 Monitoring
- ✅ Real-time metrics and alerting
- ✅ Centralized logging with retention policies
- ✅ Performance monitoring and optimization
- ✅ Cost monitoring and optimization

### 🔄 Operations
- ✅ Infrastructure as Code (IaC)
- ✅ Automated deployments
- ✅ Configuration management
- ✅ Version control and change tracking

## 🛠️ Configuration

Each module includes comprehensive variables for customization:

- **Environment-specific configurations** (dev/stg/prod)
- **Resource sizing and scaling options**
- **Security and compliance settings**
- **Cost optimization features**
- **Integration points between modules**

## 📋 Requirements

- **Terraform**: >= 1.0
- **AWS Provider**: >= 4.0
- **AWS CLI**: Configured with appropriate permissions
- **Terragrunt**: (optional) For environment management

## 🚦 Getting Started

1. Clone the repository
2. Configure AWS credentials
3. Update variable files for your environment
4. Plan and apply the infrastructure:

```bash
terraform init
terraform plan
terraform apply
```

## 📞 Support

For questions or issues:
- Review module documentation in each directory
- Check the examples in the `terragrunt/` directory
- Refer to AWS best practices documentation
- Open an issue for bugs or feature requests

---

*This infrastructure follows AWS Well-Architected Framework principles and is designed for production workloads with appropriate security, monitoring, and cost optimization.*
