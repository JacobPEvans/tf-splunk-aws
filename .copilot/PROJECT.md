# TF-Splunk-AWS Project Instructions

**AI Assistant Context File for GitHub Copilot**

## Project Overview
This is a **cost-optimized Splunk infrastructure on AWS** using Terraform and Terragrunt. The project uses a modular architecture with 4 separate modules to maintain proper separation of concerns while keeping costs under $25/month.

## Project Scope & Boundaries

### ✅ ALLOWED CHANGES
- Bug fixes in existing Terraform code
- Documentation updates and improvements
- Adding missing outputs or variables
- Security improvements that don't increase costs
- Performance optimizations within cost constraints
- Adding staging/production environment configurations

### ❌ STRICTLY FORBIDDEN CHANGES
- **DO NOT** add NAT Gateways (cost: ~$45/month each)
- **DO NOT** change instance types without cost analysis
- **DO NOT** modify the core consolidated architecture without explicit approval
- **DO NOT** automatically run `terragrunt apply`

## Change Approval Workflow

### 🟢 AUTO-APPROVED (No permission needed)
- Documentation updates
- Variable descriptions
- Output additions
- README improvements
- Comment additions

### 🟡 REQUIRES DISCUSSION (Ask user first)
- New AWS resources
- Instance type changes
- Security group modifications
- Cost-impacting changes
- Architecture modifications

### 🔴 REQUIRES EXPLICIT APPROVAL (Must get clear user consent)
- Infrastructure deployment (`terragrunt apply`)
- Regional changes
- Module restructuring
- Breaking changes to existing resources

## Cost Constraints (CRITICAL)
- **Maximum Monthly Cost**: $25
- **Current Estimated Cost**: ~$21.80/month
- **Always provide cost estimates** for any new resources
- **Always choose cheapest options** that meet requirements
- **Document cost impact** of any proposed changes

## Current Project State
- **Status**: Successfully consolidated and planned ✅
- **Last Successful Plan**: 23 resources ready to create
- **Architecture**: Single module with NAT instance (not gateway)
- **Region**: us-east-2
- **Environments**: dev (configured), stg/prod (templates ready)

## Communication Guidelines
- **Always reference this file** when making infrastructure changes
- **Explain cost impact** of any proposed modifications
- **Confirm scope** before starting major changes
- **Suggest alternatives** if user requests expensive solutions

## Project Goals (Original Objectives)
1. ✅ **Cost Optimization**: Reduced from ~$97/month to ~$21.80/month (77% savings)
2. ✅ **Modular Structure**: Organized into 4 focused modules (network, security, compute, splunk)
3. ✅ **DRY Principles**: Eliminated code duplication across modules
4. ✅ **Successful Planning**: All 23 resources validated via terragrunt plan
5. 🔄 **Future**: Deploy only when explicitly requested by user

---
*Last Updated: June 3, 2025*
*This file should be consulted before any infrastructure modifications*
