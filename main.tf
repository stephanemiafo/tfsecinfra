terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "my_az" {
  state = "available"
}

data "aws_arn" "mstacwebsti" { # Fetching a preexisting bucket for logging.
  arn = "arn:aws:s3:::mstacwebsti"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "192.168.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "my_vpc"
  }
}

resource "aws_flow_log" "my_vpc_flow_log" {
  log_destination      = aws_s3_bucket.my_tfsec_bucket.arn # Use the ARN of the S3 bucket
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.my_vpc.id
}


resource "aws_s3_bucket" "my_tfsec_bucket" {
  bucket = "my-tfsec-bucket"
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.my_tfsec_bucket.id # Specifies the S3 bucket to apply the public access block settings to.
  block_public_acls       = true                             # Blocks public access via ACLs (Access Control Lists).
  block_public_policy     = true                             # Blocks public access via bucket policies.
  ignore_public_acls      = true                             # Ignores public ACLs, making sure they don't grant public access.
  restrict_public_buckets = true                             # Restricts all public access to the bucket.
}

resource "aws_kms_key" "my_tfsec_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfsec_bucket_encryption" {
  bucket = aws_s3_bucket.my_tfsec_bucket.id # Specifies the S3 bucket to apply server-side encryption settings to.
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.my_tfsec_key.arn # Specifies the KMS master key to use for encryption.
      sse_algorithm     = "aws:kms"                    # Specifies that the encryption algorithm to use is AWS Key Management Service (KMS).
    }
  }
}

resource "aws_s3_bucket_logging" "tfsec_logging_bucket" {
  bucket        = aws_s3_bucket.my_tfsec_bucket.id
  target_bucket = "mstacwebsti" # Referencing the logging bucket.
  target_prefix = "log/"
}

resource "aws_s3_bucket_versioning" "tfsec_bucket_versioning" {
  bucket = aws_s3_bucket.my_tfsec_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
