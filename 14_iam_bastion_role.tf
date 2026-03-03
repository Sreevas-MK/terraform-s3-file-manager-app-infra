# IAM Role for bastion
resource "aws_iam_role" "bastion_role" {
  name = "${var.project_name}-bastion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Read-only access for infrastructure visibility
resource "aws_iam_policy" "bastion_readonly" {
  name = "${var.project_name}-bastion-readonly"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "autoscaling:Describe*",
          "elasticloadbalancing:Describe*",
          "ssm:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach read-only policy to role
resource "aws_iam_role_policy_attachment" "bastion_readonly_attach" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_readonly.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.project_name}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}
