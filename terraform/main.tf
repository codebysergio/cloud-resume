resource "aws_s3_bucket" "sgcrb" {
  bucket = var.bucket_name
}
resource "aws_s3_bucket_acl" "sergiogcrb-acl" {
  bucket = aws_s3_bucket.sgcrb.id
  acl    = "public-read"
}
resource "aws_s3_bucket_policy" "sergiogcrb-policy" {
  bucket = aws_s3_bucket.sgcrb.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::sergiogcrb/*"

      }
    ]
  })
}
resource "aws_s3_bucket_website_configuration" "sergiogcrb-web-config" {
  bucket = aws_s3_bucket.sgcrb.id

  index_document {
    suffix = "index.html"
  }
}
resource "aws_s3_object" "sergiogcrb-hosting-files" {
  bucket   = aws_s3_bucket.sgcrb.id
  for_each = module.dir.files

  key          = each.key
  content_type = each.value.content_type

  source  = each.value.source_path
  content = each.value.content

  etag = each.value.digests.md5
}
resource "aws_cloudfront_distribution" "main_distribution" {
  origin {
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }

    domain_name = var.s3_endpoint
    origin_id   = var.domain_name
  }
  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = var.domain_name
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  aliases = [var.domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.acm_certificate.arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_route53_zone" "primary_hosted_zone" {
  name = var.domain_name
}

data "aws_route53_zone" "route53_zone" {
  name         = var.domain_name
  private_zone = false
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