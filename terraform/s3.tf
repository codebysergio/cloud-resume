resource "aws_s3_bucket" "sergiog-cloud-resume" {
  bucket = var.bucket_name
}
resource "aws_s3_bucket_public_access_block" "resume-bucket" {
  bucket              = aws_s3_bucket.sergiog-cloud-resume.id
  block_public_acls   = false
  block_public_policy = false
}
resource "aws_s3_bucket_acl" "cloud-resume-acl" {
  bucket = aws_s3_bucket.sergiog-cloud-resume.id
  acl    = "public-read"
}
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.sergiog-cloud-resume.id

  rule {
    object_ownership = "BucketOwnerPreferred"

  }
}
resource "aws_s3_bucket_policy" "cloud-resume-policy" {
  bucket = aws_s3_bucket.sergiog-cloud-resume.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::sergiog-cloud/*"

      }
    ]
  })
}
resource "aws_s3_bucket_website_configuration" "cloud-resume-web-config" {
  bucket = aws_s3_bucket.sergiog-cloud-resume.id

  index_document {
    suffix = "index.html"
  }
}
resource "aws_s3_object" "cloud-resume-hosting-files" {
  bucket       = aws_s3_bucket.sergiog-cloud-resume.id
  key          = "index.html"
  content_type = "text/html"
  source       = "/Users/sergiogutierrez/Desktop/cres/html5up-aerial/index.html"
}