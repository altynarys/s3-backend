data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "terraform_bucket" {
    # This is a bucket to store terraform state files
    bucket        = "${var.base_name}-terraform-state-bucket"
    force_destroy = true
    tags          = merge({App = "Terraform ${var.base_name}"}, var.main_tags)
}

resource "aws_s3_bucket_versioning" "terraform_versioning" {
  bucket = aws_s3_bucket.terraform_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_versioning_bucket_config" {
  # Must have bucket versioning enabled first
  depends_on = [aws_s3_bucket_versioning.terraform_versioning]

  bucket = aws_s3_bucket.terraform_bucket.bucket

  rule {
    id = "config"
    filter {}
    noncurrent_version_expiration {
      # The number of noncurrent versions Amazon S3 will retain
      # for example, retain 5 newer noncurrent versions of the objects for 7 days
      newer_noncurrent_versions = var.newer_noncurrent_versions
      noncurrent_days           = var.noncurrent_days
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_acl" "terraform_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.example]

  bucket = aws_s3_bucket.terraform_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.terraform_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_kms_key" "key" {
  description         = "SSE-KMS key to protect terraform state objects in a bucket at rest"
  enable_key_rotation = true
  tags                = merge({App = "Terraform ${var.base_name}"}, var.main_tags)
}

resource "aws_kms_alias" "kms_key_alias" {
  name          = "alias/terraform-${var.base_name}-master-bucket-key"
  target_key_id = aws_kms_key.key.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_bucket_encryption" {
  # SSE-KMS key to protect terraform state objects in a bucket at rest
  bucket = "${var.base_name}-terraform-state-bucket"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      # AWS managed KMS master key is used if kms_master_key_id is absent 
      # while the sse_algorithm is aws:kms
      # and rotation once every 3 years automatically.
      # 
      # Otherwise, Customer managed key is used.
      # kms_master_key_id = aws_kms_key.key.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_bucket_block" {
  bucket                  = aws_s3_bucket.terraform_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_lock_table" {
    name           = "${var.base_name}-terraform-lock-table"
    read_capacity  = 5
    write_capacity = 5
    hash_key       = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
    tags = merge({App = "Terraform ${var.base_name}"}, var.main_tags)
}