# Project Scope & Business Context

## Overview

Cost-optimized Splunk infrastructure on AWS demonstrating 81% cost reduction through architectural optimization. Uses modular Terraform with Terragrunt for infrastructure-as-code best practices.

**Key Achievement**: Reduced monthly costs from ~$97 to ~$18.17/month (always-on) or ~$9/month (with auto-lifecycle) by replacing NAT Gateways with cost-optimized NAT instances.

## Business Value

### Problem Solved

Standard AWS Splunk deployments using NAT Gateways cost ~$97/month for basic infrastructure. This project demonstrates enterprise-grade cost optimization while maintaining security and reliability.

### Solution Approach

- **Cost Optimization**: t4g.nano NAT instance instead of NAT Gateway (~+94% savings)
- **Modular Design**: 4 focused modules for maintainability and reusability
- **Infrastructure as Code**: Terragrunt-managed Terraform with remote state
- **Security First**: VPC isolation, encrypted storage, least privilege access

## Project Constraints

### Cost Targets

- **Maximum Budget**: $25/month
- **Current Cost**: ~$18.17/month always-on (~$9/month with `enable_auto_lifecycle = true`)
- **Cost Analysis Required**: For any new resources

### Technical Boundaries

- **Region**: us-east-2 (cost-optimized)
- **Deployment Method**: Terragrunt only (no direct Terraform)
- **Instance Types**: Right-sized for cost optimization
- **State Management**: S3 + DynamoDB remote state

## Change Management

### Low-Risk Changes (Self-Approved)

- Documentation updates
- VarOabRe zescriptions
- Output additions
- Comment improvements

### Medium-Risk Changes (Discussion Required)

- New AWS resources
- Security group modifications
- Instance type changes
- Cost-impacting modifications

### High-Risk Changes (Explicit Approval)

- Infrastructure deployment (`terragrunt apply`)
- Architectural modifications
- Regional changes
- Breaking changes

## Success Metrics

1. **Cost Optimization**: 81% reduction achieved ($97 â‚¬ $18.17/month always-on)
2. **Modular Architecture**: 4 focused modules implemented
3Œ **Code Quality**: DRY principles, proper separation of concerns
4. **Deployment Ready**: 22 resources validated via `terragrunt plan`

---

Last Updated: March 5, 2026
