output "public_ips" {
    value = aws_instance.target[*].public_ip
}

output "instance_ids" {
    value = aws_instance.target[*].id
}

output "ansible_inventory" {
    value = templatefile("${path.module}/inventory.tpl", {
        target1_ip = aws_instance.target[0].public_ip
        target2_ip = aws_instance.target[1].public_ip
    })
}
