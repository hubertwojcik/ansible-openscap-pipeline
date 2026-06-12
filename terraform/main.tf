module "encryption" {
    source      = "./modules/encryption"
    project     = var.project
    environment = var.environment
}

module "backend" {
    source                = "./modules/backend"
    state_bucket_name     = "${var.project}-terraform-state"
    state_lock_table_name = "${var.project}-state-lock"
    project               = var.project
    environment           = var.environment
    kms_key_arn           = module.encryption.key_arn
}

module "vpc" {
    source      = "./modules/vpc"
    vpc_name    = "${var.project}-${var.environment}"
    cidr_block  = var.vpc_cidr
    subnet_cidr = var.subnet_cidr
    subnet_az   = var.subnet_az
    project     = var.project
    environment = var.environment
}

module "security_groups" {
    source      = "./modules/security-groups"
    sg_name     = "${var.project}-${var.environment}-targets-sg"
    vpc_id      = module.vpc.vpc_id
    project     = var.project
    environment = var.environment
}

module "compute" {
    source            = "./modules/compute"
    project           = var.project
    environment       = var.environment
    subnet_id         = module.vpc.subnet_id
    security_group_id = module.security_groups.security_group_id
    ssh_public_key    = var.ssh_public_key
    ami_id            = var.ami_id
    instance_type     = var.instance_type
}
