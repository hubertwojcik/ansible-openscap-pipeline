output "state_bucket_name" {
  value = aws_s3_bucket.backend_bucket.bucket
}

output "state_bucket_arn" {  
  value = aws_s3_bucket.backend_bucket.arn
}

output "state_lock_table_name" {
  value = aws_dynamodb_table.dynamodb_table.name
}

output "state_lock_table_arn" {  
  value = aws_dynamodb_table.dynamodb_table.arn
}