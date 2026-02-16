resource "aws_security_group" "ssm-to-ec2" {
  name        = local.security_group_ssm_to_ec2
  description = "ssm-to-ec2"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = local.ingress_rules_ssm_to_ec2
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.egress_rules_ssm_to_ec2
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_security_group" "ec2-to-tgw" {
  name        = local.security_group_to_tgw
  description = "ec2-to-tgw"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules_to_tgw
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules_to_tgw
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}





resource "aws_security_group" "ec2_to_rds" {
  name        = local.security_group_to_rds
  description = "ec2-to-rds"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules_to_rds
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules_to_rds
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}



resource "aws_security_group" "ec2-to-active-directory" {
  name        = var.security_group_to_active_directory
  description = "ec2-to-active-directory"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.ingress_rules_to_active_directory
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules_to_active_directory
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}



resource "aws_security_group" "cloudfront_to_ec2" {
  name        = local.security_group_cloudfront_to_ec2
  description = "Allow traffic from CloudFront Managed Prefix List"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {

    for_each = length(var.ingress_rules_cloudfront_to_ec2) > 0 ? var.ingress_rules_cloudfront_to_ec2 : []
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      prefix_list_ids = concat(ingress.value.prefix_list_ids, [data.aws_ec2_managed_prefix_list.cloudfront.id])
    }
  }

  dynamic "egress" {
    for_each = length(var.egress_rules_cloudfront_to_ec2) > 0 ? var.egress_rules_cloudfront_to_ec2 : []
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_security_group" "cf_to_alb" {
  name        = var.security_group_to_alb
  description = "Allow traffic from CloudFront Managed Prefix List"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {

    for_each = length(var.ingress_rules_cf_to_alb) > 0 ? var.ingress_rules_cf_to_alb : []
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = ingress.value.cidr_blocks
      prefix_list_ids = concat(ingress.value.prefix_list_ids, [data.aws_ec2_managed_prefix_list.cloudfront.id])
    }
  }

  dynamic "egress" {
    for_each = length(var.egress_rules_cf_to_alb) > 0 ? var.egress_rules_cf_to_alb : []
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}
