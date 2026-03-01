data "aws_vpc" "default" {
  default = true
}

data "aws_caller_identity" "current" {}


#data "aws_availability_zones" "available" {}

data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = var.zones
  }
}

# Find a certificate that is issued
data "aws_acm_certificate" "existing_cert" {
  domain      = var.acm_cert_host
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_elb_service_account" "main" {}
