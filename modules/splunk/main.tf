# Terraform module for Splunk core components (indexers, search heads)

variable "environment" {}

resource "aws_instance" "splunk_indexer" {
  ami           = "ami-12345678"
  instance_type = "t2.medium"
  tags = {
    Name = "${var.environment}-splunk-indexer"
  }
}

resource "aws_instance" "splunk_search_head" {
  ami           = "ami-12345678"
  instance_type = "t2.medium"
  tags = {
    Name = "${var.environment}-splunk-search-head"
  }
}
