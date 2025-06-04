# TF-Splunk-AWS Architecture State

**Current Infrastructure State and Technical Decisions**

## Infrastructure Overview

This document captures the **current state** of the tf-splunk-aws infrastructure to prevent accidental modifications and provide context for future changes.

## Current Architecture (Modular Structure)

### Modular Structure
- **Location**: `modules/` directory with 4 separate modules
- **Total Resources**: 22 AWS resources across all modules
- **Outputs**: Module-specific outputs aggregated in root `modules/outputs.tf`

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
```
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

## Cost Breakdown (Monthly Estimates)

| Resource | Type | Cost |
|----------|------|------|
| NAT Instance | t3.nano | $3.50 |
| Splunk Instance | t3.small | $15.33 |
| EBS Storage | 20GB GP3 | $1.60 |
| Data Transfer | Estimated | $1.37 |
| **Total** | | **~$21.80** |

## Terragrunt Structure (Simplified)

### Current Files
```
terragrunt/
├── dev/
│   ├── terragrunt.hcl     # Single environment config
├── stg/
│   └── terragrunt.hcl     # Template for staging
└── prod/
    └── terragrunt.hcl     # Template for production
```

### Current State: Modular Structure ✅
```
modules/
├── main.tf               # Root module orchestrator
├── variables.tf          # Root module variables  
├── outputs.tf            # Aggregated module outputs
├── network/              # Network infrastructure
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── security/             # Security groups & IAM
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── compute/              # NAT instance & compute
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── splunk/               # Splunk instances & EBS
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## Key Architectural Decisions

### 1. NAT Instance vs NAT Gateway
- **Decision**: Use t4g.nano NAT instance
- **Rationale**: 92% cost savings ($45 → $3.80/month per AZ)
- **Trade-off**: Single point of failure vs cost optimization
- **Implementation**: Custom user data script for NAT functionality

### 2. Modular Architecture Design
- **Decision**: Separate infrastructure into 4 logical modules
- **Rationale**: Maintain separation of concerns and reusability
- **Benefits**: Clear dependency management, easier maintenance, better testing
- **Structure**: network → security → compute → splunk dependency chain

### 3. Instance Sizing
- **Decision**: t4g.nano for NAT, t3.small for Splunk
- **Rationale**: Minimum viable sizing for cost optimization
- **Monitoring**: CloudWatch for performance validation
- **Scaling**: Can upgrade if performance issues arise

## Deployment State

### Last Successful Plan
- **Date**: Recent (consolidated architecture)
- **Resources**: 23 to be created
- **Status**: Ready for deployment
- **Command**: `terragrunt plan` (successful)

### Never Applied
- **Infrastructure**: Exists only in planning state
- **Reason**: Cost control and explicit approval requirement
- **Next Step**: Awaiting user approval for `terragrunt apply`

## Monitoring & Outputs

### Configured Outputs
- **VPC ID**: For reference in other configurations
- **Instance IDs**: NAT and Splunk instances
- **Security Group IDs**: For external access configuration
- **Cost Estimates**: Monthly breakdown for budget tracking

### CloudWatch Integration
- **Default Metrics**: Enabled for all instances
- **Custom Metrics**: Splunk performance monitoring planned
- **Alarms**: Cost and performance thresholds configured

## Backup & State Management

### Terraform State
- **Backend**: S3 with versioning enabled
- **Locking**: DynamoDB table for concurrent access prevention
- **Encryption**: State files encrypted at rest

### Configuration Backup
- **Git**: All configurations version controlled
- **Branching**: Feature branches for changes
- **Commits**: Required after successful plans

## Known Limitations

### Current Constraints
1. **Single AZ Redundancy**: NAT instance is single point of failure
2. **Instance Sizing**: Minimal sizing may require monitoring for performance
3. **Manual Scaling**: No auto-scaling configured (cost control)
4. **Development Focus**: Production hardening may require additional security

### Future Considerations
1. **High Availability**: Consider redundant NAT instances if needed
2. **Performance Monitoring**: Instance sizing validation post-deployment
3. **Security Hardening**: Additional security groups and NACLs
4. **Disaster Recovery**: Backup and recovery procedures

---

*Last Updated: June 3, 2025*  
*This document reflects the current infrastructure state after consolidation*  
*Consult before making architectural changes*
