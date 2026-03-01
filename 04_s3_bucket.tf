# S3 bucket for Node application

resource "aws_s3_bucket" "s3_node_app" {
  bucket = var.bucket_name

  tags = {
    Environment = var.project_env
    Project     = var.project_name
    Owner       = var.project_owner
  }
}

resource "aws_s3_bucket_versioning" "s3_node_app_versioning" {
  bucket = aws_s3_bucket.s3_node_app.id
  versioning_configuration {
    status = "Enabled"
  }
}


# S3 bucket to collect Application load balancer logs

resource "aws_s3_bucket" "alb_logs" {
  bucket = "sreevas-alb-access-logs-2026"
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs_lifecycle" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "delete-after-1-day"
    status = "Enabled"

    expiration {
      days = 1
    }
  }
}
