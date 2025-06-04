# TF-Splunk-AWS

Cost-optimized Splunk infrastructure on AWS using Terraform and Terragrunt.

## Overview

This repository contains a Terragrunt-driven Terraform configuration for deploying and managing a remote Splunk environment on AWS. It follows infrastructure-as-code best practices with a DRY, modular architecture that supports multiple environments (e.g., dev, staging, prod).

**Cost Target**: ~$21.80/month (vs ~$97/month with NAT Gateways)

## Architecture

### Modular Structure
- **Network Module**: VPC, subnets, routing, internet gateway
- **Security Module**: Security groups, IAM roles and policies  
- **Compute Module**: Cost-optimized NAT instance (t3.nano)
- **Splunk Module**: Splunk instance (t3.small) with EBS storage

### Module Dependencies
```
network → security → compute → splunk
```

## Features

- **Cost Optimized**: t3.nano NAT instance instead of expensive NAT Gateways
- **Terragrunt-managed**: Environment hierarchy with remote state management
- **Modular Architecture**: 4 focused modules with clear separation of concerns
- **Security First**: Encrypted EBS volumes, IAM roles, security groups
- **Multi-AZ Support**: High availability across availability zones
- **CloudWatch Integration**: Comprehensive logging and monitoring

## Quick Start

1. **Bootstrap** (one-time setup):
   ```bash
   cd bootstrap
   terraform init
   terraform apply
   ```

2. **Deploy Infrastructure**:
   ```bash
   cd terragrunt/dev
   terragrunt plan
   terragrunt apply
   ```

## Cost Breakdown

| Resource | Type | Monthly Cost |
|----------|------|--------------|
| NAT Instance | t3.nano | $3.50 |
| Splunk Instance | t3.small | $15.33 |
| EBS Storage | 20GB GP3 | $1.60 |
| Data Transfer | Estimated | $1.37 |
| **Total** | | **~$21.80** |

## Documentation

- **[Project Scope & Guidelines](.copilot/PROJECT.md)** - Change approval workflow and boundaries
- **[Architecture & Current State](.copilot/ARCHITECTURE.md)** - Technical decisions and infrastructure state
- **[Module Documentation](modules/README.md)** - Detailed module information

## Important Notes

- **Always use Terragrunt** - Never run Terraform commands directly
- **Cost Conscious** - Current setup saves 77% vs standard NAT Gateway approach
- **State Management** - Uses S3 + DynamoDB for remote state storage
- **Security** - All EBS volumes encrypted, least privilege IAM policies
