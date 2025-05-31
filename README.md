## Overview

This repository contains a Terragrunt-driven Terraform configuration for deploying and managing a remote Splunk environment on AWS. It follows infrastructure-as-code best practices with a DRY, modular architecture that supports multiple environments (e.g., dev, staging, prod).

## Features

- Terragrunt-managed environment hierarchy
- Modular Terraform codebase using logical units (networking, compute, storage, security)
- Configurable support for Splunk components:
  - Deployment server
  - Indexers
  - Search heads
  - Heavy forwarders
- Secure VPC, IAM roles, and EBS volumes provisioned for Splunk
- Optionally integrates with CloudWatch, S3, ELB, and Auto Scaling
- Remote state storage and locking (e.g., S3 + DynamoDB)
