# Adding domain A record.

resource "aws_route53_record" "webserver" {

  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = var.application_host
  type    = "A"
  alias {
    name                   = aws_lb.s3_app_alb.dns_name
    zone_id                = aws_lb.s3_app_alb.zone_id
    evaluate_target_health = true
  }
}
