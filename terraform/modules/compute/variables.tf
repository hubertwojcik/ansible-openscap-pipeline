variable "project" {
    type = string
}

variable "environment" {
    type = string
}

variable "subnet_id" {
    type = string
}

variable "security_group_id" {
    type = string
}

variable "ssh_public_key" {
    type        = string
    description = "Public key content for EC2 key pair (stored as GitHub Secret)"
}

variable "ami_id" {
    type        = string
    description = "Ubuntu 22.04 LTS AMI ID for eu-north-1"
    default     = "ami-088fd024fe7aa5070"
}

variable "instance_type" {
    type    = string
    default = "t3.micro"
}
