# TF-Splunk-AWS

Cost-optimized Splunk infrastructure on AWS using Terraform and Terragrunt.
**22 resources, ~$9–$17.67/month**.

## What & Why

**What**: Production-ready Splunk deployment on AWS with modular Terraform architecture
**Why**: Demonstrates cost optimization, infrastructure-as-code best practices, and security-first design

## Quick Facts

- **Cost**: ~$9/month (lifecycle) or ~$17.67/month (always-on)
- **Architecture**: 4 modules (network, security, compute, splunk)
- **Deployment**: Terragrunt-managed with remote state
- **Security**: Encrypted storage, IAM least privilege, VPC isolation

## Cost Breakdown

| Resource | Always-On | With Auto-Lifecycle |
| -------- | --------- | ------------------- |
| NAT Instance (t4g.nano) | $2.52 | $2.52 |
| Splunk Instance (t4g.small) | $12.18 | ~$3.05 (25% utilization) |
| EBS Storage (70GB GP3) | $2.97 | $2.97 |
| S3 SmartStore | — | ~$0.50 |
| **Total** | **~$17.67** | **~$9** |

Auto-lifecycle starts Splunk every 4 hours for 60 minutes (6 hrs/day = 25% utilization).
Data persists permanently in S3 via SmartStore and remains searchable on-demand.

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
