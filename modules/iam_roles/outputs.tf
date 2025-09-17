output "role_name" {
  value = aws_iam_role.ec2_ssm_role.name
}

output "role_arn" {
  value = aws_iam_role.ec2_ssm_role.arn
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_ssm_profile.name
}
