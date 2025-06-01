# Compute module outputs

output "ec2_instances" {
  description = "EC2 instance details"
  value = {
    for k, v in aws_instance.ec2_instances : k => {
      id         = v.id
      private_ip = v.private_ip
      public_ip  = v.public_ip
    }
  }
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = var.ecs_enabled ? aws_ecs_cluster.main[0].id : null
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = var.ecs_enabled ? aws_ecs_cluster.main[0].arn : null
}

output "ecs_services" {
  description = "ECS service details"
  value = var.ecs_enabled ? {
    for k, v in aws_ecs_service.services : k => {
      id   = v.id
      name = v.name
      arn  = v.arn
    }
  } : {}
}

output "security_group_id" {
  description = "Default compute security group ID"
  value       = aws_security_group.compute_default.id
}

output "iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2_role.arn
}

output "iam_instance_profile_name" {
  description = "EC2 IAM instance profile name"
  value       = aws_iam_instance_profile.ec2_profile.name
}
