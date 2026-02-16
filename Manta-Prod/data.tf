# # Find the VPC first so we can search within it
# data "aws_vpc" "main" {
#   filter {
#     name   = "tag:Name"
#     values = [var.vpc_name]
#   }
# }




# # Find the specific Subnet using the Name from your variable list
# data "aws_subnet" "selected" {
#   vpc_id = aws_vpc.main.id

#   filter {
#     name   = "tag:Name"
#     values = [var.subnet_private_names[0]] # Takes the first name in your list
#   }
# }


data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }

  # tags = {
  #   Tier = var.public_subnet_tag
  # }

  filter {
    name   = "tag:Name"
    values = ["subnet-compiulation-test-public*"]
  }
}

data "aws_subnets" "rds_subnets" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }


  filter {
    name   = "tag:Name"
    values = var.subnet_rds_names
  }
}

# data "aws_s3_bucket" "cloudfront-bucket" {
#   bucket = "test.compilation.backups"
# }


data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# # Look up IDs based on the names provided in tfvars


data "aws_security_group" "individual" {
  for_each = toset(var.security_group_names) 
  name     = each.value
  vpc_id   = aws_vpc.main.id
}


# data.tf
data "aws_security_groups" "selected" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }

  filter {
    name   = "group-name"
    values = var.security_group_names # Ensure all SGs used in ec2_configs are in this list
  }
}

