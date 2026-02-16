resource "aws_vpc_endpoint" "ssm_endpoints" {
  count = length(local.ssm_endpoint_types)

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.${local.ssm_endpoint_types[count.index]}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private_subnets[*].id
  security_group_ids  = [aws_security_group.ssm-to-ec2.id]
  private_dns_enabled = true

  tags = {
    Name = "SSM Endpoint - ${local.ssm_endpoint_types[count.index]}"
  }
}
