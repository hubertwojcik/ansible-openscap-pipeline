resource "aws_vpc" "main" {
    cidr_block = var.cidr_block

    tags = {
        Name        = var.vpc_name
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_subnet" "public" {
    vpc_id                  = aws_vpc.main.id
    availability_zone       = var.subnet_az
    cidr_block              = var.subnet_cidr
    map_public_ip_on_launch = true

    tags = {
        Name        = "${var.vpc_name}-public"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        Name        = "${var.vpc_name}-igw"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name        = "${var.vpc_name}-rt"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}
