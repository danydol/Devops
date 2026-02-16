
aws_profile_name = "shayg-il"

########################################################################################################################


vpc_name             = "vpc-manta-prod"
account_name_private = "manta-prod_private"
account_name_public  = "manta-prod_public"
rtb_name_private     = "rtb-manta-prod-private"
rtb_name_public      = "rtb-manta-prod-public"
vpc_cidr_block       = "10.114.0.0/19"
subnet_private_names = ["subnet-manta-prod-private-az1", "subnet-manta-prod-private-az2"]
subnet_private_cidrs = ["10.114.1.0/24", "10.114.2.0/24"]
subnet_public_names  = ["subnet-manta-prod-public-az1", "subnet-manta-prod-public-az2"]
subnet_public_cidrs  = ["10.114.3.0/24", "10.114.4.0/24"]
subnet_rds_names     = ["subnet-manta-prod-rds-az1", "subnet-manta-prod-rds-az2"]
subnet_rds_cidrs     = ["10.114.5.0/24", "10.114.6.0/24"]




##############################################################################################################################

transit_gateway_subnet_ids = []
tags = {
  Environment = "Prod"
}


#################################################################################################################################


create_s3_bucket = false
bucket_names = [
  "share-bucket-manta-dev-prod",
  "test.compilation.clients",
  "test.compilation.file"
]
#environment = "manta-dev"



#################################################################################################################################


create_igw = false
igw_tags   = "compilation-test-IGW"


###################################################################################################################################

nat_gateway_num = 0


###################################################################################################################################

create_ec2_instances = true

ec2_configs = {
  "manta-prod-app" = {
    instance_name       = "manta-prod-app"
    ami_id              = "ami-0a313bf8989d15b9c"
    instance_type       = "r6i.large"
    subnet_index        = 0
    root_volume_size    = 100
    root_volume_type    = "gp3"
    second_volume_name  = "/dev/sdb"
    second_volume_size  = 150
    second_volume_type  = "gp3"
    security_group_list = ["ssm-to-ec2", "ec2-to-tgw", "ec2-to-active-directory"]
  },
  "manta-prod-integration" = {
    instance_name       = "manta-prod-integration"
    ami_id              = "ami-0a313bf8989d15b9c"
    instance_type       = "t3.xlarge"
    subnet_index        = 0
    root_volume_size    = 100
    root_volume_type    = "gp3"
    second_volume_name  = "/dev/sdb"
    second_volume_size  = 150
    second_volume_type  = "gp3"
    security_group_list = ["ssm-to-ec2", "ec2-to-tgw", "ec2-to-active-directory"]
  },
  "manta-prod-reports" = {
    instance_name       = "manta-prod-reports"
    ami_id              = "ami-0a313bf8989d15b9c"
    instance_type       = "m5.xlarge"
    subnet_index        = 0
    root_volume_size    = 100
    root_volume_type    = "gp3"
    second_volume_name  = "/dev/sdc"
    second_volume_size  = 150
    second_volume_type  = "gp3"
    security_group_list = ["ssm-to-ec2", "ec2-to-tgw", "ec2-to-active-directory"]
  }
}








security_group_names = [
  "ssm-to-ec2",
  "ec2-to-rds",
  "ec2-to-tgw",
  "ec2-to-active-directory"
]

#######################################################################################################################################

#RDS:

create_db_instance     = false
allocated_storage      = 20
storage_type           = "gp3"
db_name                = null
identifier             = "manta-prod-db"
rds_engine             = "sqlserver-web"
parameter_group_name   = "default.sqlserver-web-15.0"
instance_class         = "db.t3.small"
is_publicly_accessible = false
db_username            = "admin"


############################################################################################################################

#CloudFront

create_distribution = false



##############################################################################################################################

# security Group

enable_tgw_access        = false
enable_cloudfront_access = false
ingress_rules_cloudfront_to_ec2 = [
  {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = [] # Leave empty if using prefix list
    prefix_list_ids = [] # The code handles this via the Data Source
  }
]
egress_rules_cloudfront_to_ec2 = []



############################################################################################################################3

# Load Balancer 
create_load_balancer = false
load_balancer_name   = "manta-dev-alb"
load_balancer_type   = "application"




