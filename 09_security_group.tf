# Security group for Load balancer

resource "aws_security_group" "load_balancer" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_env}-loadbalancer"
  description = "${var.project_name}-${var.project_env}-loadbalancer"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "HTTP from Internet"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id] # CloudFront managed prefix list
  }


  tags = {
    Environment = var.project_env
    Project     = var.project_name
    Owner       = var.project_owner
  }
}


# Security group for backend

resource "aws_security_group" "backend" {

  vpc_id      = aws_vpc.main.id
  name        = "${var.project_name}-${var.project_env}-backend"
  description = "${var.project_name}-${var.project_env}-backend"

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "HTTP from loadbalancer"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }


  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_instance.openvpn_instance.private_ip}/32"]
  }


  tags = {
    Environment = var.project_env
    Project     = var.project_name
    Owner       = var.project_owner
  }
}


resource "aws_security_group" "openvpn_sg" {
  name        = "${var.project_name}-openvpn-sg"
  description = "Allow VPN traffic"
  vpc_id      = aws_vpc.main.id

  # Allow OpenVPN web interface
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Allow OpenVPN UDP port (default 1194) for VPN tunnel
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
