output "website_url" {
  description = "url of site"
  value       = aws_s3_bucket_website_configuration.cloud-resume-web-config.website_endpoint
}

