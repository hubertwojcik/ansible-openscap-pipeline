resource "aws_security_group" "target_nodes" {
    name        = var.sg_name
    description = "Security group for OpenSCAP target nodes - allows SSH from GitHub Actions"
    vpc_id      = var.vpc_id

    tags = {
        Name        = var.sg_name
        Project     = var.project
        Environment = var.environment
        ManagedBy   = "terraform"
    }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
    security_group_id = aws_security_group.target_nodes.id
    ip_protocol       = "tcp"
    from_port         = 22
    to_port           = 22
    cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
    security_group_id = aws_security_group.target_nodes.id
    ip_protocol       = "-1"
    cidr_ipv4         = "0.0.0.0/0"
}
