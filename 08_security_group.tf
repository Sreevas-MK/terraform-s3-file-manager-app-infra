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
    prefix_list_ids = ["pl-9aa247f3"] # CloudFront managed prefix list
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
    description     = "SSH access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }


  tags = {
    Environment = var.project_env
    Project     = var.project_name
    Owner       = var.project_owner
  }
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  # SSH from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Allow all outbound (internet access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-bastion-sg"
    Environment = var.project_env
  }
}

