data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # This pulls the actual thumbprint from the live certificate
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}


resource "aws_iam_policy" "github_deploy_policy" {
  name        = "GitHubActionsWorkflowPolicy"
  description = "Policy for GitHub Actions to deploy codes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetBucketVersioning", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.s3_code_bucket}",
          "arn:aws:s3:::${var.s3_code_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        # Dynamically uses your account ID
        Resource = [
          "arn:aws:codedeploy:ap-south-1:${data.aws_caller_identity.current.account_id}:application:S3-node-app-deploy",
          "arn:aws:codedeploy:ap-south-1:${data.aws_caller_identity.current.account_id}:deploymentgroup:S3-node-app-deploy/Development-group",
          "arn:aws:codedeploy:ap-south-1:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "github_code_deploy_role" {
  name = "github-code-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.github_code_repo}:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.github_code_deploy_role.name
  policy_arn = aws_iam_policy.github_deploy_policy.arn
}

