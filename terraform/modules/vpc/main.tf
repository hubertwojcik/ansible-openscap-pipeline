resource "aws_vpc" "main_vpc" {
    cidr_block = var.cidr_block

    tags = {
        Name        = var.vpc_name
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_subnet" "first_subnet" {
    vpc_id                  = aws_vpc.main_vpc.id
    availability_zone       = var.subnet_az[0]
    cidr_block              = var.subnet_cidr[0]
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.vpc_name}-subnet-1"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_subnet" "second_subnet" {
    vpc_id                  = aws_vpc.main_vpc.id
    availability_zone       = var.subnet_az[1]
    cidr_block              = var.subnet_cidr[1]
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.vpc_name}-subnet-2"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
        Name        = var.internet_gateway_name
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table" "route_table" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }

    tags = {
        Name        = "${var.vpc_name}-rt"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table_association" "first_subnet" {
    subnet_id      = aws_subnet.first_subnet.id
    route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "second_subnet" {
    subnet_id      = aws_subnet.second_subnet.id
    route_table_id = aws_route_table.route_table.id
}
