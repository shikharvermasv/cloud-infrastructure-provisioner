output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr
}

output "subnet_id" {
  value = module.vpc.public_subnet_id
}

output "internet_gateway_id" {
  value = module.vpc.internet_gateway_id
}

output "route_table_id" {
  value = module.vpc.route_table_id
}

output "instance_id" {
  value = module.ec2.instance_id
}

output "instance_private_ip" {
  value = module.ec2.private_ip
}

output "instance_public_ip" {
  value = module.ec2.public_ip
}

output "security_group_id" {
  value = module.ec2.security_group_id
}

output "iam_role_name" {
  value = module.iam.role_name
}

output "iam_role_arn" {
  value = module.iam.role_arn
}

output "instance_profile_name" {
  value = module.iam.instance_profile_name
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "private_instance_id" {
  value = module.private_ec2.instance_id
}

output "private_instance_ip" {
  value = module.private_ec2.private_ip
}

output "private_security_group_id" {
  value = module.private_ec2.security_group_id
}

output "ssm_instance_profile_name" {
  value = module.ssm.instance_profile_name
}

# output "nat_gateway_id" {
#   value = module.vpc.nat_gateway_id
# }