resource "aws_route_table" "rtb_private_subnet" {
  count = var.nat_gateway_num > 0 ? var.nat_gateway_num : 1

  vpc_id = aws_vpc.main.id
  dynamic "route" {
    for_each = var.nat_gateway_num > 0 ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  dynamic "route" {
    for_each = var.nat_gateway_num == 0 ? [1] : []

    content {
      cidr_block         = "0.0.0.0/0"
      transit_gateway_id = aws_ec2_transit_gateway_vpc_attachment.tgw-attachment[count.index].transit_gateway_id
    }
  }


  tags = {
    Name = var.rtb_name_private
  }
}

resource "aws_route_table" "rtb_public_subnet" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.create_igw ? [1] : []

    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw[each.index].id
    }
  }

  tags = {
    Name = var.rtb_name_public
  }
}

resource "aws_route_table_association" "subnet_private_names_az" {
  count          = length(aws_route_table.rtb_private_subnet)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.rtb_private_subnet[0].id
}

resource "aws_route_table_association" "subnet_public_names_az" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.rtb_public_subnet.id
}
