output "vpc_id" {
    value = aws_vpc.main_vpc.id
  }
  
output "subnet_ids" {
    value = [
      aws_subnet.first_subnet.id,
      aws_subnet.second_subnet.id
    ]
  }