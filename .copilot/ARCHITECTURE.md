# Technical Architecture

Infrastructure Design & Implementation Details

## Architecture Overview

Cost-optimized Splunk infrastructure using modular Terraform design. This document provides technical implementation details for the 22-resource AWS infrastructure.

*For cost breakdown and business context, see [main README](../README.md)*

## Module Architecture

### Structure

- **4 Focused Modules**: Network, Security, Compute, Splunk
- **Total Resources**: 22 AWS resources
- **Orchestration**: Root module coordinates all sub-modules

### Module Organization

1. **Network Module** (`modules/network/`): VPC, subnets, routing, internet gateway
2. **Security Module** (`modules/security/`): Security groups, IAM roles and policies  
3. **Compute Module** (`modules/compute/`): NAT instance and basic compute resources
4. **Splunk Module** (`modules/splunk/`): Splunk instance, EBS volumes, CloudWatch

### Root Module

- **Orchestrator**: `modules/main.tf` coordinates all sub-modules
- **Dependencies**: Proper module dependency chain maintained
- **Variables**: Centralized in `modules/variables.tf`

### Regional Configuration

- **Region**: `us-east-2`
- **Availability Zones**: `us-east-2a`, `us-east-2b`
- **State Backend**: S3 bucket with DynamoDB locking

### Network Architecture

```text
VPC (10.0.0.0/16)
├── Public Subnets
│   ├── us-east-2a: 10.0.1.0/24
│   └── us-east-2b: 10.0.2.0/24
└── Private Subnets
    ├── us-east-2a: 10.0.3.0/24
    └── us-east-2b: 10.0.4.0/24
```

### Compute Resources

#### NAT Instance (Cost Optimized)

- **Type**: `t4g.nano` (~$3.02/month)
- **AMI**: Amazon Linux 2 (data source)
- **Purpose**: Replace expensive NAT Gateways (~$45/month each)
- **Location**: Public subnet with source/destination check disabled

#### Splunk Instance

- **Type**: `t3.small` (~$15.18/month)
- **Storage**: 20GB GP3 encrypted (~$1.60/month)
- **AMI**: Amazon Linux 2 (data source)
- **Location**: Private subnet

### Security Configuration

#### Security Groups

1. **NAT Security Group**: HTTP/HTTPS outbound, SSH access
2. **Splunk Security Group**: Splunk ports (8000, 9997, 8089), SSH access

#### IAM Configuration

- **Splunk Instance Profile**: EC2 access with SSM permissions
- **Principle of Least Privilege**: Minimal required permissions only

## Cost Efficiency

*Complete cost breakdown available in [main README](../README.md)*

## Terragrunt Environment Structure

```hcl
terragrunt/
├── dev/terragrunt.hcl     # Development environment
├── stg/terragrunt.hcl     # Staging template  
└── prod/terragrunt.hcl    # Production template
```

## Module Structure

```text
modules/
├── main.tf               # Root module orchestrator
├── variables.tf          # Root module variables  
├── outputs.tf            # Aggregated module outputs
├── network/              # Network infrastructure
├── security/             # Security groups & IAM
├── compute/              # NAT instance & compute
└── splunk/               # Splunk instances & EBS
```

## Key Architectural Decisions

### NAT Instance vs NAT Gateway

- **Decision**: Use t4g.nano NAT instance
- **Rationale**: 92% cost savings ($45 → $3.80/month per AZ)
- **Trade-off**: Single point of failure vs cost optimization

### Modular Architecture Design

- **Decision**: Separate infrastructure into 4 logical modules
- **Rationale**: Maintain separation of concerns and reusability
- **Benefits**: Clear dependency management, easier maintenance

### Instance Sizing

- **Decision**: t4g.nano for NAT, t3.small for Splunk
- **Rationale**: Minimum viable sizing for cost optimization
- **Monitoring**: CloudWatch for performance validation

## Deployment State

### Current Status

- **Resources**: 22 to be created
- **Status**: Ready for deployment (plan successful)
- **Infrastructure**: Exists only in planning state
- **Next Step**: Awaiting approval for `terragrunt apply`

## Key Outputs

- **VPC ID**: For reference in other configurations
- **Instance IDs**: NAT and Splunk instances
- **Security Group IDs**: For external access configuration

## State Management

- **Backend**: S3 with versioning and DynamoDB locking
- **Encryption**: State files encrypted at rest
- **Version Control**: All configurations in Git

---

Last Updated: June 3, 2025
