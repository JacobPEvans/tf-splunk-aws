# Compute Module Outputs

output "nat_instance_id" {
  description = "ID of the NAT instance"
  value       = aws_instance.nat.id
}

output "nat_instance_private_ip" {
  description = "Private IP address of the NAT instance"
  value       = aws_instance.nat.private_ip
}

output "nat_instance_public_ip" {
  description = "Public IP address of the NAT instance"
  value       = aws_instance.nat.public_ip
}

output "nat_primary_network_interface_id" {
  description = "Primary network interface ID of NAT instance (for routing)"
  value       = aws_instance.nat.primary_network_interface_id
}

output "nat_cloudwatch_log_group" {
  description = "CloudWatch log group for NAT instance"
  value       = aws_cloudwatch_log_group.nat_instance.name
}
