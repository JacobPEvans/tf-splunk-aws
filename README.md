# TF-Splunk-AWS

Cost-optimized Splunk infrastructure on AWS using Terraform and Terragrunt.
**22 resources, ~$17.67/month** (Phase 1); planned ~$9/month with Phase 2+3.

## What & Why

**What**: Production-ready Splunk deployment on AWS with modular Terraform architecture
**Why**: Demonstrates cost optimization, infrastructure-as-code best practices, and security-first design

## Quick Facts

- **Cost**: ~$17.67/month (Phase 1); ~$9/month with planned Phase 2+3
- **Architecture**: 4 modules (network, security, compute, splunk)
- **Deployment**: Terragrunt-managed with remote state
- **Security**: Encrypted storage, IAM least privilege, VPC isolation

## Cost Breakdown

| Resource | Phase 1 (this PR) | Planned Phase 2+3 |
| -------- | ----------------- | ----------------- |
| NAT Instance (t4g.nano) | $2.52 | $2.52 |
| Splunk Instance (t4g.small) | $12.18 | ~$3.05 (25% utilization) |
| EBS Storage (70GB GP3) | $2.97 | $2.97 |
| Planned S3 SmartStore | — | ~$0.50 |
| **Total** | **~$17.67** | **~$9** |

Phase 2 will add SmartStore-backed S3 data persistence.
Phase 3 will add auto-lifecycle management (start every 4 hours for 60 minutes).

## Quick Start

```bash
cd terragrunt/dev
terragrunt plan    # Review 22 resources
terragrunt apply   # Deploy infrastructure
```

## Documentation

| Document | Purpose | Read Time |
| -------- | ------- | --------- |
| **[Project Scope](.copilot/PROJECT.md)** | Business context, constraints | 2 min |
| **[Architecture](.copilot/ARCHITECTURE.md)** | Technical decisions, current state | 5 min |
| **[Implementation](modules/README.md)** | Module details, developer guide | 10 min |
