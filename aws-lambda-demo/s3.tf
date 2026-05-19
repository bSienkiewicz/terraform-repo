resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "brtk-test-bucket-via-tf"

  tags = {
    Name        = "Learning Bucket"
    Environment = "Dev"
  }
}