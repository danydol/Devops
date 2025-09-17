module "global" {
  source = "../../global"
}

// --- VPC ---
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  assign_generated_ipv6_cidr_block = var.enable_ipv6
  enable_dns_hostnames = true
  enable_dns_support = true
  

  tags = {
    Name = "VPC-Checkpoint-FW-Inspection"
  }
}

/* // --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
} */

// --- Public Subnets ---
resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets_map

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnets_bit_length, each.value)
  ipv6_cidr_block = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, var.subnets_bit_length, each.value) : null
  map_public_ip_on_launch = true
  tags = {
    Name = format("Checkpoint-Gateways Public Subnet %s", each.value)
  }
}

// --- Private Subnets ---
resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets_map

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnets_bit_length, each.value)
  ipv6_cidr_block = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, var.subnets_bit_length, each.value) : null
  map_public_ip_on_launch = false
  tags = {
    Name = format("Checkpoint-Gateways Private Subnet %s", each.value)
  }
}

// --- tgw Subnets ---
resource "aws_subnet" "tgw_subnets" {
  for_each = var.tgw_subnets_map

  vpc_id = aws_vpc.vpc.id
  availability_zone = each.key
  cidr_block = cidrsubnet(aws_vpc.vpc.cidr_block, var.subnets_bit_length, each.value)
  ipv6_cidr_block = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, var.subnets_bit_length, each.value) : null
  tags = {
    Name = format("Checkpoint-TGW-Subnet %s", each.value)
  }
}


// --- Routes ---
resource "aws_route_table" "public_subnet_rtb" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "Checkpoint-Gateways Public Subnets Route Table"
  }
}
/* resource "aws_route" "vpc_internet_access" {
  route_table_id = aws_route_table.public_subnet_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}
resource "aws_route" "vpc_internet_access_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
  route_table_id = aws_route_table.public_subnet_rtb.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id = aws_internet_gateway.igw.id
} */
resource "aws_route_table_association" "public_rtb_to_public_subnets" {
  for_each = { for public_subnet in aws_subnet.public_subnets : public_subnet.cidr_block => public_subnet.id }
  route_table_id = aws_route_table.public_subnet_rtb.id
  subnet_id = each.value
}


resource "aws_route_table" "cp_private_subnet1_rtb" {
  depends_on = [ aws_ec2_transit_gateway_vpc_attachment.cp-fw-vpc-TGW-Attachment ]

  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.tgw_id
  }
  tags = {
    Name = "Checkpoint Private Subnet 1 Route Table"
    Network = "Private"
  }
}
resource "aws_route_table_association" "cp_private_subnet1_rtb_assoc" {
  subnet_id      = values(aws_subnet.private_subnets)[0].id
  route_table_id = aws_route_table.cp_private_subnet1_rtb.id
}


resource "aws_route_table" "cp_private_subnet2_rtb" {
  depends_on = [ aws_ec2_transit_gateway_vpc_attachment.cp-fw-vpc-TGW-Attachment ]

  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.tgw_id
  }
  tags = {
    Name = "Checkpoint Private Subnet 2 Route Table"
    Network = "Private"
  }
}
resource "aws_route_table_association" "cp_private_subnet2_rtb_assoc" {
  subnet_id      = values(aws_subnet.private_subnets)[1].id
  route_table_id = aws_route_table.cp_private_subnet2_rtb.id
}


resource "aws_route_table" "cp_private_subnet3_rtb" {
  depends_on = [ aws_ec2_transit_gateway_vpc_attachment.cp-fw-vpc-TGW-Attachment ]

  vpc_id = aws_vpc.vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = var.tgw_id
  }
  tags = {
    Name = "Checkpoint Private Subnet 3 Route Table"
    Network = "Private"
  }
}
resource "aws_route_table_association" "cp_private_subnet3_rtb_assoc" {
  subnet_id      = values(aws_subnet.private_subnets)[2].id
  route_table_id = aws_route_table.cp_private_subnet3_rtb.id
}




#######################
# Transit Gateway Attachments
#######################


resource "aws_ec2_transit_gateway_vpc_attachment" "cp-fw-vpc-TGW-Attachment" {
  subnet_ids             = [for subnet in aws_subnet.tgw_subnets : subnet.id]
  transit_gateway_id     = var.tgw_id
  vpc_id                 = aws_vpc.vpc.id
  appliance_mode_support = "enable"

  tags = {
    Name = "Checkpoint-FW-VPC-TGW-Attachment"
  }
}


#######################
# VPC Endpoints
#######################

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints_sg" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Checkpoint-VPC-Endpoints-SG"
  }
}


# EC2 VPC Endpoint
resource "aws_vpc_endpoint" "ec2_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${module.global.org_vars.region}.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnets : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "Checkpoint-EC2-VPC-Endpoint"
  }
}



# EC2 msgs VPC Endpoint
resource "aws_vpc_endpoint" "ec2_msg_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${module.global.org_vars.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnets : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "Checkpoint-EC2-Msgs-VPC-Endpoint"
  }
}



# Auto Scaling VPC Endpoint
resource "aws_vpc_endpoint" "auto_scaling_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${module.global.org_vars.region}.autoscaling"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnets : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "Checkpoint-Auto-Scaling-VPC-Endpoint"
  }
}



# ELB VPC Endpoint
resource "aws_vpc_endpoint" "elb_endpoint" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${module.global.org_vars.region}.elasticloadbalancing"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for subnet in aws_subnet.private_subnets : subnet.id]
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "Checkpoint-ELB-VPC-Endpoint"
  }
}


