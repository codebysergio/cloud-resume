terraform {
  backend "s3" {
    bucket         = "sergiogcr-tf-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}
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
  key          = "index.html"
  content_type = "text/html"
  source  = "/Users/sergiogutierrez/Desktop/cres/html5up-aerial/index.html"
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

resource "aws_dynamodb_table" "views-dynamodb-table" {
  name           = "Web-Views"
  hash_key       = "id"
  billing_mode   = "PROVISIONED"
  write_capacity = 5
  read_capacity  = 5

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "views" {
  table_name = aws_dynamodb_table.views-dynamodb-table.name
  hash_key   = aws_dynamodb_table.views-dynamodb-table.hash_key


  item = <<ITEM
  {
     "id": {"S": "1"},
     "views": {"N": "1"}
  }
  ITEM
}
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "iam_policy_for_resume_project" {

  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
            "dynamodb:GetItem",
            "dynamodb:PutItem"
          ],
          "Resource" : "arn:aws:dynamodb:us-east-1:471112822169:table/Web-Views"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.iam_policy_for_resume_project.arn

}
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "dbscript.py"
  output_path = "dbscript_function_payload.zip"
}

resource "aws_lambda_function" "db_function" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "db_function_name"
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "dbscript.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.8"
}

resource "aws_lambda_function_url" "dbfunction_live" {
  function_name      = aws_lambda_function.db_function.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}