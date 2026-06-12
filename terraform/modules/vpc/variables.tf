variable "vpc_name" {
    type = string
}

variable "cidr_block" {
    type    = string
    default = "10.0.0.0/16"
}

variable "subnet_cidr" {
    type    = string
    default = "10.0.1.0/24"
}

variable "subnet_az" {
    type = string
}

variable "project" {
    type = string
}

variable "environment" {
    type = string
}
