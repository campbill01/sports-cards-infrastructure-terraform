resource "aws_s3_bucket" "terraform_state_us_west_2" {
  provider = aws.us_west_2
  bucket = "sports-cards-terraform-state-bucket-us-west-2"

  tags = {
    Name        = "Terraform State Bucket us-west-2"
    Project     = "sports-cards"
    ManagedBy   = "terraform"
    Environment = "all"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_us_west_2" {
  provider = aws.us_west_2
  bucket = aws_s3_bucket.terraform_state_us_west_2.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_us_west_2" {
  provider = aws.us_west_2
  bucket = aws_s3_bucket.terraform_state_us_west_2.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_us_west_2" {
  provider = aws.us_west_2
  bucket = aws_s3_bucket.terraform_state_us_west_2.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks_us_west_2" {
  provider = aws.us_west_2
  name         = "sports-cards-terraform-locks-us-west-2"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks us-west-2"
    Project     = "sports-cards"
    ManagedBy   = "terraform"
    Environment = "all"
  }
}
