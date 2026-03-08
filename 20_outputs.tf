output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.s3_app_alb.dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "app_url" {
  description = "Application URL via Route53"
  value       = "https://${aws_route53_record.app.name}"
}

output "openvpn_public_ip" {
  description = "Public IP of OpenVPN instance"
  value       = data.aws_instance.openvpn_instance.public_ip
}

output "backend_instance_private_ips" {
  description = "Private IPs of backend instances in ASG"
  value       = data.aws_instances.backend_instances.private_ips
}
