# Instance Management — Pause & Resume

Procedures for stopping and starting the Splunk dev/DR instances to save money
without destroying any infrastructure or data.

## What Persists Across Stop/Start

| Resource | Persists? | Notes |
| ---------- | --------- | ----- |
| EBS root volume | Yes | OS, Splunk install, config |
| EBS data volume | Yes | Splunk index data (hot/warm) |
| S3 SmartStore | Yes | Cold/frozen index data |
| SSM parameters | Yes | Admin password |
| Security groups | Yes | Firewall rules |
| IAM role | Yes | Instance permissions |
| VPC / subnets | Yes | Network topology |
| **Public IP** | **No** | New IP assigned on each start |
| Instance ID | Yes | Does not change |

> EBS data + S3 SmartStore = full index history survives any stop/start cycle.

---

## Cost Analysis

### Always-On (baseline)

| Resource | Monthly |
| ---------- | ------- |
| NAT t4g.nano (us-east-2) | ~$2.52 |
| Splunk t3a.small (us-east-2) | ~$12.18 |
| EBS 70 GB gp3 | ~$2.97 |
| S3 SmartStore | ~$0.50 |
| **Total** | **~$18.17** |

### Paused (instances stopped, data retained)

| Resource | Monthly |
| ---------- | ------- |
| NAT t4g.nano — stopped | $0.00 |
| Splunk t3a.small — stopped | $0.00 |
| EBS 70 GB gp3 (still billed) | ~$2.97 |
| S3 SmartStore | ~$0.50 |
| **Total** | **~$3.47** |

### With Auto-Lifecycle (EventBridge scheduled)

Default config: start every 4 hours, run 60 minutes = ~25% utilization.

| Resource | Monthly |
| ---------- | ------- |
| Splunk t3a.small × 25% | ~$3.05 |
| NAT t4g.nano (must stay on to receive data) | ~$2.52 |
| EBS + S3 | ~$3.47 |
| **Total** | **~$9.04** |

---

## Pause Procedure (stop both instances)

Get the instance IDs from Terraform outputs first:

```bash
cd ~/git/tf-splunk-aws/feature/docs-instance-management  # or main/
aws-vault exec tf-splunk-aws -- terragrunt output
```

Note `splunk_instance_id` and `nat_instance_id` from the output.

### Stop Splunk first (drain in-flight data)

```bash
aws-vault exec tf-splunk-aws -- aws ec2 stop-instances \
  --instance-ids <splunk_instance_id> \
  --region us-east-2
```

Wait for Splunk to reach `stopped` state (~30–60 s):

```bash
aws-vault exec tf-splunk-aws -- aws ec2 wait instance-stopped \
  --instance-ids <splunk_instance_id> \
  --region us-east-2
```

### Stop NAT

```bash
aws-vault exec tf-splunk-aws -- aws ec2 stop-instances \
  --instance-ids <nat_instance_id> \
  --region us-east-2

aws-vault exec tf-splunk-aws -- aws ec2 wait instance-stopped \
  --instance-ids <nat_instance_id> \
  --region us-east-2
```

Both instances are now stopped. EBS and S3 continue to bill; compute does not.

---

## Resume Procedure (start instances, get new IP)

### Start NAT first (restores routing before Splunk)

```bash
aws-vault exec tf-splunk-aws -- aws ec2 start-instances \
  --instance-ids <nat_instance_id> \
  --region us-east-2

aws-vault exec tf-splunk-aws -- aws ec2 wait instance-running \
  --instance-ids <nat_instance_id> \
  --region us-east-2
```

### Start Splunk

```bash
aws-vault exec tf-splunk-aws -- aws ec2 start-instances \
  --instance-ids <splunk_instance_id> \
  --region us-east-2

aws-vault exec tf-splunk-aws -- aws ec2 wait instance-running \
  --instance-ids <splunk_instance_id> \
  --region us-east-2
```

### Get the new public IP

```bash
aws-vault exec tf-splunk-aws -- aws ec2 describe-instances \
  --instance-ids <splunk_instance_id> \
  --region us-east-2 \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text
```

Splunk Web is available at `http://<new-ip>:8000` after ~2–3 minutes boot time
(user_data runs on every boot: installs Splunk if needed, retrieves SSM password,
starts Splunk, applies SmartStore config).

---

## Notes

### State drift

Terraform does not manage instance power state, so stopping instances via AWS CLI
does not create plan drift. A `terragrunt plan` after pause will show no changes.

### Boot time

Allow ~2–3 minutes after `instance-running` before Splunk Web is reachable.
The `user_data` script runs at every boot. SSM password retrieval adds ~5–10 s.

### Data ingestion during pause

On-prem forwarders will queue events locally (Splunk's disk-based queue) and
replay them when connectivity is restored. No events are lost as long as the
on-prem queue does not fill up.

### Auto-lifecycle alternative

If you want automated cost control without manual steps, set
`enable_auto_lifecycle = true` in `terragrunt/dev/terragrunt.hcl`. This uses
EventBridge Scheduler to start Splunk on a configurable interval
(`lifecycle_interval_hours`, default 4) and shut it down automatically after
`auto_shutdown_minutes` (default 60). The NAT instance must remain running to
receive forwarded data.

### Elastic IP (EIP)

The current dev deployment does not use an EIP, so the Splunk public IP changes
on every start. To get a stable IP, add an EIP resource to the compute module
and associate it with the Splunk instance. EIPs are free when attached to a
running instance; they cost ~$3.65/mo when unattached (i.e., while Splunk is
paused). Factor that into the cost model before enabling.
