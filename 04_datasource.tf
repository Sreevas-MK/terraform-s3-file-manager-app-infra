data "aws_caller_identity" "current" {}

# Find a certificate that is issued
data "aws_acm_certificate" "existing_cert" {
  domain      = var.acm_cert_host
  statuses    = ["ISSUED"]
  most_recent = true
}


data "aws_route53_zone" "my_domain" {
  name         = var.domain_name
  private_zone = false
}

# AMI for backend instances
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


data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}


data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}


# AMI for OVPN instance
data "aws_ami" "ubuntu_20" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Data required to fetch OVPN instance details 
data "aws_instance" "openvpn_instance" {
  filter {
    name   = "tag:Name"
    values = ["OpenVPN-AS"] # This must match the 'name' variable in your module
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }

  depends_on = [module.ec2-openvpn]
}


data "aws_instances" "backend_instances" {
  filter {
    name   = "tag:aws:autoscaling:groupName"
    values = [aws_autoscaling_group.backend_instance_autoscaling_group.name]
  }

  instance_state_names = ["running"]
}
