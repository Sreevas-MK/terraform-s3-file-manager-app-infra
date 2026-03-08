module "ec2-openvpn" {
  source = "rizkiprass/ec2-openvpn-as/aws"

  name                          = "OpenVPN-AS"
  instance_type                 = "t2.micro"
  ami_id                        = data.aws_ami.ubuntu_20.id
  key_name                      = aws_key_pair.ssh_auth_key.key_name
  vpc_id                        = aws_vpc.main.id
  ec2_subnet_id                 = aws_subnet.public_subnets[0].id
  user_openvpn                  = "devuser"
  routing_ip                    = aws_vpc.main.cidr_block # All private subnets
  create_vpc_security_group_ids = false
  vpc_security_group_ids        = [aws_security_group.openvpn_sg.id]
  iam_instance_profile          = aws_iam_instance_profile.ec2_instance_profile.name

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 20
    },
  ]

  tags = {
    Project     = var.project_name
    Environment = var.project_env
  }
}

