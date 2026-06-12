terraform {
  backend "s3" {
    bucket = "ansible-openscap-pipeline-terraform-state"
    key = "terraform.state"
    region = "eu-north-1"
    dynamodb_table = "ansible-openscap-pipeline-state-lock"
    encrypt = true
  }
}
