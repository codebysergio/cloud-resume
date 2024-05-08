data "archive_file" "lambda" {
  type        = "zip"
  source_file = "dbscript.py"
  output_path = "dbscript_function_payload.zip"
}

resource "aws_lambda_function" "db_function" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "db_function"
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