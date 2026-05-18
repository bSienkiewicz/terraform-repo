resource "aws_dynamodb_table" "visitor_logs" {
  name         = "visitor_logs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "visitor_ip"

  attribute {
    name = "visitor_ip"
    type = "S"
  }

  tags = {
    Name        = "Visitor Logs"
    Environment = "Dev"
  }
}
