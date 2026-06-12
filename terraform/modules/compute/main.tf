resource "aws_key_pair" "deployer" {
    key_name   = "${var.project}-${var.environment}-key"
    public_key = var.ssh_public_key

    tags = {
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_instance" "target" {
    count = 2

    ami                    = var.ami_id
    instance_type          = var.instance_type
    subnet_id              = var.subnet_id
    vpc_security_group_ids = [var.security_group_id]
    key_name               = aws_key_pair.deployer.key_name

    tags = {
        Name        = "${var.project}-${var.environment}-target-${count.index + 1}"
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
        Role        = "openscap-target"
    }
}
