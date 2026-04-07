output "app_server_ip" {
  value = aws_instance.app_server.public_ip
}

output "jenkins_server_ip" {
  value = aws_instance.jenkins_server.public_ip
}