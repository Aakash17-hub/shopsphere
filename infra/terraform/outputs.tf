output "minikube_private_ip" {
  value = aws_instance.minikube.private_ip
}

output "security_group_name" {
  value = aws_security_group.shopsphere.name
}
