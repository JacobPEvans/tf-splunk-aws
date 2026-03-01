# GitHub Copilot Instructions — tf-splunk-aws

## Repository Purpose

Cost-optimized Splunk infrastructure on AWS using OpenTofu + Terragrunt. Manages
network, security, compute, and Splunk modules for AWS Splunk DR infrastructure.

## CRITICAL: OpenTofu, Not Terraform

This repo uses **OpenTofu** (`tofu`), not Terraform. Never generate `terraform` CLI commands.
The binary is `tofu`. All HCL is OpenTofu-compatible.

## Running Commands

All commands must be wrapped with aws-vault and Doppler:

```bash
aws-vault exec terraform -- doppler run -- terragrunt <COMMAND>
```

For plan/apply:

```bash
aws-vault exec terraform -- doppler run -- terragrunt plan
aws-vault exec terraform -- doppler run -- terragrunt apply
```

## Technology Stack

- **OpenTofu** (not Terraform) — IaC engine
- **Terragrunt** — wrapper for DRY config and remote state
- **Doppler** — secrets management (runtime env vars)
- **aws-vault** — AWS credentials
- **SOPS/age** — encrypted secrets in repo

## Module Structure

Four modules under `modules/`: network, security, compute, splunk.
Terragrunt config in `terragrunt/` directory.

## HCL Conventions

- Module inputs in `variables.tf`, outputs in `outputs.tf`, providers in `providers.tf`
- Use `deployment.json` for environment-specific non-secret config
- Terragrunt config in `terragrunt.hcl` at each module root

## CI

The `Terraform CI` workflow validates HCL syntax and runs `tofu validate`.
Fix all validation errors before merging.
