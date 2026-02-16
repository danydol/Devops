variable "aws_profile_name" {
  description = "aws cli profile name "
  type        = string
  default     = null
}




variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string

}

variable "account_name_private" {
  description = "name of the account the code is deployed to"
  type        = string
  default     = null
}


variable "rtb_name_private" {
  description = "name of the account the code is deployed to"
  type        = string
  default     = null
}

variable "account_name_public" {
  description = "name of the account the code is deployed to"
  type        = string
  default     = null
}


variable "rtb_name_public" {
  description = "name of the account the code is deployed to"
  type        = string
  default     = null
}




variable "vpc_name" {
  description = "the vpc name"
  type        = string
  #default     = "vpc-compilation-test"
}

variable "aws_region" {
  description = "AWS region for the deployment  "
  type        = string
  default     = "il-central-1"
}


variable "tags" {
  description = "Tags for the VPC"
  type        = map(string)
  default = {
    Environment = "Test"
  }
}



variable "subnet_private_cidrs" {
  type        = list(string)
  description = "private subnets"
}

variable "subnet_private_names" {
  description = "names of the private subnets"
  type        = list(string)
}

variable "private_availability_zones" {
  type        = list(string)
  description = "AZs to deploy all private subnets to"
  default     = ["il-central-1a", "il-central-1b"]
}


variable "subnet_private_tags" {
  description = "Tags for the subnets"
  type        = map(string)
  default = {
    Environment = "Test"
  }
}

variable "subnet_public_cidrs" {
  type        = list(string)
  description = "public subnets"
}

variable "subnet_public_names" {
  type = list(string)
}

# variable "public_subnet_tag" {
#   description = "The tag value used to identify public subnets"
#   type        = list(string)

# }



variable "public_availability_zones" {
  type        = list(string)
  description = "AZs to deploy all public subnets to"
  default     = ["il-central-1a", "il-central-1b"]
}


variable "subnet_public_tags" {
  description = "Tags for the subnets"
  type        = map(string)
  default = {
    Environment = "Test"
  }
}

variable "create_tgwa" {
  description = "whether to create tgwa or not"
  type        = bool
  default     = false
}

variable "transit_gateway_subnet_ids" {
  description = "subnet ids for transit gateway"
  type        = list(string)
  default     = []
}

variable "subnet_rds_cidrs" {
  type        = list(string)
  description = "rds subnets"
}

variable "subnet_rds_names" {
  type        = list(string)
  description = "names for the RDS subnets"
}

variable "rds_availability_zones" {
  type        = list(string)
  description = "AZs to deploy rds subnets to"
  default     = ["il-central-1a", "il-central-1b"]
}

variable "subnet_rds_tags" {
  description = "Tags for the subnets"
  type        = map(string)
  default = {
    Environment = "Test"
  }
}


# variable "max_session_duration" {
#   description = "The maximum session duration for the IAM role in seconds"
#   type        = number

# }





variable "enable_tgw_access" {
  type        = bool
  default     = true
  description = "Set to true to allow traffic from CloudFront prefix lists"
}



variable "ingress_rules_to_tgw" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}




variable "egress_rules_to_tgw" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))


  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}


variable "enable_cloudfront_access" {
  type        = bool
  default     = false
  description = "Set to true to allow traffic from CloudFront prefix lists"
}

variable "create_distribution" {
  type    = bool
  default = true
}







variable "egress_rules_cloudfront_to_ec2" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}



variable "ingress_rules_cloudfront_to_ec2" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    prefix_list_ids = list(string)
  }))

  default = [
    {
      from_port       = 0
      to_port         = 0
      protocol        = -1
      cidr_blocks     = ["0.0.0.0/0"]
      prefix_list_ids = []
    }
  ]
}




variable "enable_alb" {
  type        = bool
  default     = false
  description = "Set to true to allow traffic from CloudFront prefix lists"
}

variable "security_group_to_alb" {
  description = "cf-to-alb"
  type        = string
  default     = "cf-to-alb"
}

variable "ingress_rules_cf_to_alb" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = list(string)
    prefix_list_ids = list(string)
  }))
  default = [
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = []
      prefix_list_ids = []
    }
  ]
}


variable "egress_rules_cf_to_alb" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

}

variable "create_load_balancer" {
  description = "Controls if the ALB should be created"
  type        = string
  default     = "application"
}

variable "load_balancer_type" {
  description = "load-balancer-type"
  type        = string
  default     = "application"

}


variable "load_balancer_name" {
  description = "load-balancer-name"
  type        = string
  default     = "main-load-balancer"
}


# variable "security_group_to_rds" {
#   description = "List of security group names to look up"
#   type        = list(string)
# }



variable "create_db_instance" {
  description = "create db instance"
  type        = bool
  default     = false
}





variable "db_name" {
  description = "Admin user for RDS"
  type        = string
  sensitive   = true
}


variable "db_username" {
  description = "Admin user for RDS"
  type        = string
  sensitive   = true
}



variable "allocated_storage" {
  description = "The amount of storage (in GB) to allocate for the RDS instance"
  type        = number
  sensitive   = true
}

variable "storage_type" {
  description = "The type of storage to use for the RDS instance"
  type        = string
  sensitive   = true
}


variable "rds_engine" {
  description = "The database engine to use"
  type        = string
  sensitive   = true
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  sensitive   = true
}


variable "is_publicly_accessible" {
  description = "Expose RDS services"
  type        = bool

}


variable "parameter_group_name" {
  description = "parameter_group_name"
  type        = string
}

variable "identifier" {
  description = "db instnace name"
  type        = string
}

variable "ingress_rules_to_rds" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

}

variable "egress_rules_to_rds" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "security_group_names" {
  description = "List of security group names to look up"
  type        = list(string)
}

variable "security_group_to_active_directory" {
  description = "ec2-to-active-directory"
  type        = string
  default     = "ec2-to-active-directory"
}

variable "ingress_rules_to_active_directory" {
  description = "List of ingress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["10.100.0.0/16"]
    }
  ]

}

variable "egress_rules_to_active_directory" {
  description = "List of egress rules for the security group"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["10.100.0.0/16"]
    },
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      cidr_blocks = ["10.110.0.0/16"]
    }
  ]
}



variable "bucket_names" {
  description = "The name of the S3 bucket"
  type        = list(string)
  default     = []
}






variable "s3_bucket_names" {
  description = "The name of the S3 bucket"
  type        = list(string)
  default     = []
}

variable "create_s3_bucket" {
  description = "A boolean flag to determine if the bucket should be created"
  type        = bool
  default     = false
}





variable "create_igw" {
  description = "Internet Gateway"
  type        = bool
  default     = true

}

variable "igw_name" {
  type        = string
  default     = ""
  description = "igw_name"
}

variable "igw_tags" {
  type        = string
  default     = ""
  description = "description"
}

variable "nat_gateway_num" {
  description = "Number of NAT Gateways to create"
  type        = number
  default     = 0
}



variable "common_tags" {
  type = map(string)
  default = {
    Project = "Infrastructure"
  }
}



variable "create_ec2_instances" {
  description = "Master boolean to enable/disable EC2 creation"
  type        = bool
  default     = true
}

variable "ec2_configs" {
  description = "Map of server configurations to avoid hardcoding"
  type = map(object({
    ami_id              = string
    instance_type       = string
    instance_name       = string
    subnet_index        = number
    root_volume_size    = number
    root_volume_type    = string
    second_volume_name  = string
    second_volume_size  = number
    second_volume_type  = string
    security_group_list = list(string)
  }))

}
  