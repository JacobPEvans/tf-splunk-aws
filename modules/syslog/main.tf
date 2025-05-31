# Terraform module for Splunk core components (indexers, search heads)

variable "environment" {}

resource "aws_instance" "syslog" {
  ami           = "ami-12345678"
  instance_type = "t2.medium"
  tags = {
    Name = "${var.environment}-syslog"
  }
}