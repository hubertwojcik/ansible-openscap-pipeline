data "aws_caller_identity" "current" {}

resource "aws_kms_key" "kms_key" {
    deletion_window_in_days = 10
    enable_key_rotation     = true
    policy = jsonencode({
        Version = "2012-10-17"
        Id      = "key-default-1"
        Statement = [
            {
                Sid    = "Enable IAM User Permissions"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                }
                Action   = "kms:*"
                Resource = "*"
            },
        ]
    })
    tags = {
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}
