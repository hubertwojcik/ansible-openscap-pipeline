[targets]
target-1 ansible_host=${target1_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ansible-openscap
target-2 ansible_host=${target2_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/ansible-openscap

[targets:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
