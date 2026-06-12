terraform {
  # Backend bootstrapping: run `terraform apply` first to create the S3 bucket,
  # then uncomment this block and run `terraform init -migrate-state`
  # backend "s3" {
  #   bucket         = "ansible-openscap-pipeline-terraform-state"
  #   key            = "terraform.tfstate"
  #   region         = "eu-north-1"
  #   use_lockfile   = true
  #   encrypt        = true
  # }
}
