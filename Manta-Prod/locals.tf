
locals {

  ingress_rules_ssm_to_ec2 = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr_block]
    }
  ]
  egress_rules_ssm_to_ec2 = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = [var.vpc_cidr_block]
    }
  ]

  assume_role_principal = "ec2.amazonaws.com"



  transit_gateway_id = "tgw-0430826c231550bf5"

  availability_zone                = "il-central-1a"
  disable_api_termination          = true
  iam_instance_profile_name        = "ec2-instance-profile"
  ec2_role_name                    = "ssm-ec2-role"
  associate_public_ip_address      = false
  security_group_ssm_to_ec2        = "ssm-to-ec2"
  security_group_to_tgw            = "ec2-to-tgw"
  security_group_cloudfront_to_ec2 = "cloudfront-to-ec2"
  security_group_to_alb            = "cf-to-alb"
  security_group_to_rds            = "ec2-to-rds"


  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true


  ssm_endpoint_types = ["ssm", "ssmmessages", "ec2messages"]

  

}
