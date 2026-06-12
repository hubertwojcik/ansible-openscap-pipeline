output "target_public_ips" {
    value = module.compute.public_ips
}

output "ansible_inventory" {
    value = module.compute.ansible_inventory
}
