variable "project" {
    type    = string
    default = "ansible-openscap-pipeline"
}

variable "environment" {
    type    = string
    default = "dev"
}

variable "vpc_cidr" {
    type    = string
    default = "10.0.0.0/16"
}

variable "subnet_cidr" {
    type    = string
    default = "10.0.1.0/24"
}

variable "subnet_az" {
    type    = string
    default = "eu-north-1a"
}

variable "ssh_public_key" {
    type        = string
    description = "Public key content for EC2 SSH access"
}

variable "ami_id" {
    type    = string
    default = "ami-088fd024fe7aa5070"
}

variable "instance_type" {
    type    = string
    default = "t3.micro"
}
