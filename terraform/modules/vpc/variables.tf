variable "vpc_name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "subnet_cidr" {
    type = list(string)
}

variable "subnet_az" {
    type = list(string)
}

variable "internet_gateway_name" {
    type = string
}


variable "environment" {
    type = string
}

variable "project" {
    type = string
}
