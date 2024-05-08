resource "aws_acm_certificate" "acm_certificate" {
  domain_name               = var.domain_name
  validation_method         = "DNS"
  subject_alternative_names = [var.alt_names]


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "aws_acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record : record.fqdn]
}