data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codedeploy_service" {
  name               = "codedeploy-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codedeploy_service.name
}

resource "aws_codedeploy_app" "s3_app" {
  name = "S3-node-app-deploy"
}

resource "aws_codedeploy_deployment_group" "s3_app_group" {
  app_name              = aws_codedeploy_app.s3_app.name
  deployment_group_name = "Development-group"
  service_role_arn      = aws_iam_role.codedeploy_service.arn

  autoscaling_groups = [aws_autoscaling_group.backend_instance_autoscaling_group.name]

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  deployment_style {
    deployment_option = local.deployment_option
    deployment_type   = local.deployment_type
  }

  dynamic "load_balancer_info" {
    for_each = local.deployment_type == "BLUE_GREEN" ? [1] : []
    content {
      target_group_info {
        name = aws_lb_target_group.s3_app_tg.name
      }
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }
}
