# Terraform Modules for Splunk AWS Infrastructure

This directory contains modular Terraform configurations for deploying cost-optimized Splunk infrastructure on AWS. The modules follow separation of concerns principles and AWS best practices.

## 📁 Module Structure

### Root Module

- **main.tf**: Orchestrates all sub-modules with proper dependencies
- **variables.tf**: Centralized variable definitions
- **outputs.tf**: Aggregated outputs from all modules

### Infrastructure Modules

#### 🌐 `network/`

Networking foundation:

- VPC with DNS resolution enabled
- Public/private subnets across multiple AZs  
- Internet Gateway for public connectivity
- Route tables for traffic routing

#### 🔒 `security/`

Security and access management:

- Security groups for NAT and Splunk instances
- IAM roles and policies for EC2 instances
- Principle of least privilege access

#### 💻 `compute/`

Cost-optimized compute resources:

- t3.nano NAT instance (replaces expensive NAT Gateway)
- CloudWatch log groups for monitoring
- User data scripts for NAT functionality

#### 🔍 `splunk/`

Splunk infrastructure:

- t3.small Splunk instance
- Encrypted EBS volumes for data storage
- CloudWatch integration for logging
- User data scripts for Splunk setup

## Key Features

- Cost-optimized NAT instance (saves ~$45/month vs NAT Gateway)
- CloudWatch integration for monitoring  
- Automated user data scripts
- Proper security group configuration

## 💰 Cost Efficiency

For detailed cost breakdown, see [main README](../README.md).

## 🚀 Usage

### Terragrunt Deployment (Recommended)

This infrastructure is designed to be deployed via Terragrunt for proper state management:

```bash
# Navigate to environment directory
cd terragrunt/dev

# Plan the deployment
terragrunt plan

# Review the plan output, then apply
terragrunt apply
### Module Dependencies

```text
network (VPC, subnets, routing)
    ↓
security (security groups, IAM)
    ↓  
compute (NAT instance)
    ↓
splunk (Splunk instance + EBS)
```

## 📋 Requirements

- **Terraform**: >= 1.0
- **AWS Provider**: ~> 5.0
- **AWS CLI**: Configured with appropriate permissions
- **Terragrunt**: Required for deployment

## 🚦 Getting Started

1. Clone the repository
2. Configure AWS credentials
3. Update Terragrunt configuration files for your environment
4. Plan and apply the infrastructure:

```bash
cd terragrunt/dev
terragrunt plan
# After reviewing the plan, only apply manually:
terragrunt apply
```

**IMPORTANT**: Always use Terragrunt commands, never direct Terraform. All infrastructure management is handled through Terragrunt for proper state management and environment isolation.

## 📞 Support

For questions or issues:

- Review module documentation in each directory
- Check the examples in the `terragrunt/` directory
- Refer to AWS best practices documentation
- Open an issue for bugs or feature requests

---

*This infrastructure follows AWS Well-Architected Framework principles and is designed for production workloads with appropriate security, monitoring, and cost optimization.*
