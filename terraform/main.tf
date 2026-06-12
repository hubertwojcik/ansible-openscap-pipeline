module "encryption" {
  source      = "./modules/encryption"
  project     = var.project
  environment = var.environment
}

module "backend" {
  source = "./modules/backend"

  state_bucket_name     = "${var.project}-terraform-state"
  state_lock_table_name = "${var.project}-state-lock"
  project               = var.project
  environment           = var.environment
  kms_key_arn           = module.encryption.key_arn
}