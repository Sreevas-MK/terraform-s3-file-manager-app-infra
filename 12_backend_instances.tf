resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-${var.project_env}-instance-profile"
  role = aws_iam_role.ec2_s3_iam_role.name
}

resource "aws_launch_template" "backend_instance_template" {

  name        = "${var.project_name}-${var.project_env}-template"
  description = "${var.project_name}-${var.project_env}-template"

  instance_type = "t2.micro"
  image_id      = data.aws_ami.amazon_linux.id
  key_name      = aws_key_pair.ssh_auth_key.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.backend.id]

  user_data = base64encode(file("./files/setup.sh"))

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-backend"
      Environment = var.project_env
      Project     = var.project_name
      Owner       = var.project_owner
    }
  }
}

resource "aws_autoscaling_group" "backend_instance_autoscaling_group" {

  name                      = "${var.project_name}-${var.project_env}"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = aws_subnet.private_subnets[*].id
  target_group_arns         = [aws_lb_target_group.s3_app_tg.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.project_env}-backend"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.backend_instance_template.id
    version = aws_launch_template.backend_instance_template.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 120
    }
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  for_each = toset(var.log_groups)

  name              = each.value
  retention_in_days = 1
}
