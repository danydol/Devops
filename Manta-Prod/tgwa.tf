resource "aws_ec2_transit_gateway_vpc_attachment" "tgw-attachment" {
  count              = var.create_tgwa ? 0 : 1
  transit_gateway_id = local.transit_gateway_id
  vpc_id             = aws_vpc.main.id
  subnet_ids         = aws_subnet.private_subnets[*].id
  tags               = var.tags
}
