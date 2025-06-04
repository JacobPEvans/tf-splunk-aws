# TF-Splunk-AWS

Cost-optimized Splunk infrastructure on AWS using Terraform and Terragrunt.
**22 resources, ~$21.80/month**.

## What & Why

**What**: Production-ready Splunk deployment on AWS with modular Terraform architecture  
**Why**: Demonstrates cost optimization, infrastructure-as-code best practices, and security-first design

## Quick Facts

- **Cost**: ~$21.80/month
- **Architecture**: 4 modules (network, security, compute, splunk)
- **Deployment**: Terragrunt-managed with remote state
- **Security**: Encrypted storage, IAM least privilege, VPC isolation

## Cost Breakdown

| Resource | Monthly Cost |
|----------|--------------|
| NAT Instance (t3.nano) | $3.50 |
| Splunk Instance (t3.small) | $15.33 |
| EBS Storage (70GB GP3) | $2.97 |
| **Total** | **$21.80** |

## Quick Start

```bash
cd terragrunt/dev
terragrunt plan    # Review 22 resources
terragrunt apply   # Deploy infrastructure
```

## Documentation

| Document | Purpose | Read Time |
|----------|---------|-----------|
| **[Project Scope](.copilot/PROJECT.md)** | Business context, constraints | 2 min |
| **[Architecture](.copilot/ARCHITECTURE.md)** | Technical decisions, current state | 5 min |
| **[Implementation](modules/README.md)** | Module details, developer guide | 10 min |
