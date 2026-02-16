# 1. Create 2 Elastic IPs
resource "aws_eip" "nat_eip" {
  count  = var.nat_gateway_num
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "nat-eip-${count.index}"
  })
}

# 2. Create 2 NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.nat_gateway_num

  # Assign the EIPs created above
  allocation_id = aws_eip.nat_eip[count.index].id

  # Place each NAT in a different public subnet
  subnet_id = aws_subnet.public_subnets[count.index].id

  tags = merge(var.common_tags, {
    Name = "nat-gateway-${count.index}"
  })

  # Best practice: ensure IGW exists before creating NAT
  # depends_on = [aws_internet_gateway.gw] 
}