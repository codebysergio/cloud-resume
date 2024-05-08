resource "aws_route53_zone" "primary_hosted_zone" {
  name = var.domain_name
}

data "aws_route53_zone" "route53_zone" {
  name         = var.domain_name
  private_zone = false
  depends_on   = [aws_route53_zone.primary_hosted_zone]
}

resource "aws_route53_record" "Main" {
  name    = var.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.route53_zone.zone_id

  alias {
    name                   = aws_cloudfront_distribution.main_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.main_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "route53_record" {
  for_each = {
    for dvo in aws_acm_certificate.acm_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.zone_id
}