resource "aws_dynamodb_table" "lock" {
  name         = "terraform-lock-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
