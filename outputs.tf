output "ec2_machines_apache" {
  value = aws_instance.nginx-cs.*.arn  # Here * indicates that there are more than one arn as we used count as 4   
}

output "ec2_machine_nginx" {
  value = aws_instance.apache-cs.*.arn  # Here * indicates that there are more than one arn as we used count as 4   
}