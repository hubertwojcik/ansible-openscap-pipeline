resource "aws_s3_bucket" "backend_bucket" {
    bucket = var.state_bucket_name

    tags = {
        Name        = var.state_bucket_name
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
    bucket = aws_s3_bucket.backend_bucket.id

    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_sse" {
    bucket = aws_s3_bucket.backend_bucket.id

    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm     = "aws:kms"
            kms_master_key_id = var.kms_key_arn
        }
    }
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
    bucket = aws_s3_bucket.backend_bucket.id

    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_dynamodb_table" "dynamodb_table" {
    name         = var.state_lock_table_name
    billing_mode = "PAY_PER_REQUEST"
    hash_key     = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    point_in_time_recovery {
        enabled = true
    }

    server_side_encryption {
        enabled     = true
        kms_key_arn = var.kms_key_arn
    }

    tags = {
        Name        = var.state_lock_table_name
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}
