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