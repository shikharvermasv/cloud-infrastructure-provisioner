output "security_group_id" {
  value = aws_security_group.ssm_endpoints.id
}

output "ssm_endpoint_id" {
  value = aws_vpc_endpoint.ssm.id
}

output "ssmmessages_endpoint_id" {
  value = aws_vpc_endpoint.ssmmessages.id
}

output "ec2messages_endpoint_id" {
  value = aws_vpc_endpoint.ec2messages.id
}