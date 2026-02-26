# tf-splunk-aws

AWS Splunk DR/backup infrastructure managed with Terraform and Terragrunt.

## Purpose

This repo provisions a cost-optimized AWS environment for backup/DR of a local home-lab Splunk instance. Key constraints:

- Data flows **INTO** AWS only (never out - egress costs)
- Only a minimal data receiver needs 24/7 uptime
- Search capability is on-demand (start/stop as needed)
- Cost sensitivity is paramount

## Architecture

```text
MODULES
  network  -> VPC, subnets, route tables (us-east-2)
  security -> Security groups, IAM role/profile
  compute  -> NAT instance (t4g.nano, public subnet)
  splunk   -> Splunk Enterprise (t4g.small, private subnet)

DATA FLOW
  On-Prem Splunk -> HEC (port 8088) -> AWS Splunk Receiver (private subnet via NAT)
  Cloud Sources  -> HEC (port 8088) -> AWS Splunk Receiver

NETWORK
  VPC: 10.0.0.0/16
  Public:  10.0.1.0/24, 10.0.2.0/24 (NAT instance lives here)
  Private: 10.0.10.0/24, 10.0.20.0/24 (Splunk lives here)
```

## Cost (~$21.80/mo)

| Resource | Instance | Cost |
| -------- | -------- | ---- |
| NAT | t3.nano | ~$3.80/mo |
| Splunk | t3.small | ~$15.03/mo |
| EBS (70GB gp3) | - | ~$2.97/mo |

Graviton migration planned (see issue #23) — would reduce cost to ~$17.67/mo.
Use scheduled scaling to stop Splunk off-hours for additional savings.

## Technology Stack

- **Terraform/OpenTofu** >= 1.0
- **AWS Provider** ~> 6.0
- **Terragrunt** for environment management
- **SSM Parameter Store** for secrets

## Commands

### Prerequisites

- `aws-vault` for AWS credential management
- `doppler` for environment variable injection (if using Doppler secrets)

### Terraform Operations

```bash
# From terragrunt/dev/
aws-vault exec terraform -- terragrunt init
aws-vault exec terraform -- terragrunt plan
aws-vault exec terraform -- terragrunt apply

# From modules/ (for testing without real credentials)
tofu init -backend=false
tofu validate
tofu test -no-color
```

### Bootstrap (first-time setup)

```bash
# From bootstrap/
aws-vault exec terraform -- terraform init
aws-vault exec terraform -- terraform apply
```

## Module Structure

```text
modules/
├── main.tf         # Root orchestrator, wires modules together
├── variables.tf    # Root input variables
├── outputs.tf      # Aggregated outputs
├── network/        # VPC, subnets, route tables, IGW
├── security/       # Security groups, IAM role/profile
├── compute/        # NAT instance (source_dest_check=false)
└── splunk/         # Splunk Enterprise instance + EBS
```

## Secrets Management

**NEVER** commit passwords or credentials. Use:

- `aws_ssm_parameter` for Splunk admin password
- `aws-vault` for AWS credentials
- Instance role + SSM for instance-level secrets

## Testing

Tests use mock providers - no AWS credentials needed:

```bash
cd modules/
tofu init -backend=false
tofu test -no-color
```

## Security Notes

- SSH disabled by default (`enable_ssh_access = false`)
- Use SSM Session Manager for shell access (already installed on all instances)
- All instances in private subnets except NAT
- Splunk accessible only from within VPC

## Critical: Version Management

Pin dependency versions for reproducibility. Use `~> X.Y` for patch-level flexibility
while locking major/minor versions. This avoids unexpected breaking changes from upstream
updates while still receiving bug fixes.

- Use `~> X.Y` (e.g., `~> 6.0`) for provider versions — allows patch releases, locks major/minor
- Use `>= X.Y` only when a minimum version is required and newer versions are all acceptable
- Avoid overly tight constraints (e.g., `= X.Y.Z`) unless exact reproducibility is critical

## Development Workflow

**Before ANY commits**, run validation:

```bash
# Validate syntax (no credentials needed)
tofu init -backend=false
tofu validate

# Full plan (requires AWS credentials)
aws-vault exec terraform -- terragrunt plan
```

**Best Practices**:

- Use feature branches for all changes
- Follow conventional commit messages
- Mark secrets with `sensitive = true` in variables
- Never commit `.terraform/` or state files
- Remote state with encryption (S3 + DynamoDB)

## PR Review Checklist

- [ ] No exposed secrets or credentials
- [ ] Variables documented with `sensitive = true` where needed
- [ ] `tofu validate` passes (no credentials needed)
- [ ] Conventional commit message
- [ ] Documentation updated if needed
- [ ] Cost impact considered
