
module "global" {
  source = "./global"
}

/* module "ec2_keypair" {
  source = "./modules/ec2_keypair"

  key_name = local.ec2_keypair_name
} */

module "cloudguard-network-security_tgw_gwlb_master" {
  source  = "./modules/tgw_gwlb_master"

  // --- VPC Network Configuration --
  vpc_cidr = "100.65.0.0/16"
  private_subnets_map = {
    "il-central-1a" = 1
    "il-central-1b" = 2
    "il-central-1c" = 3
  }
  tgw_subnets_map = {
    "il-central-1a" = 5
    "il-central-1b" = 6
    "il-central-1c" = 7
  }
  subnets_bit_length = 8

  availability_zones = ["il-central-1a", "il-central-1b", "il-central-1c"]
  number_of_AZs      = 3

  /* nat_gw_subnet_1_cidr = "100.65.13.0/24"
  nat_gw_subnet_2_cidr = "100.65.23.0/24"
  nat_gw_subnet_3_cidr = "100.65.33.0/24" */

  gwlbe_subnet_1_cidr = "100.65.14.0/24"
  gwlbe_subnet_2_cidr = "100.65.24.0/24"
  gwlbe_subnet_3_cidr = "100.65.34.0/24"

  // --- General Settings ---
  key_name                     = "checkpoint-ec2-keypair_v2"
  enable_volume_encryption     = false
  volume_size                  = 400
  enable_instance_connect      = false
  disable_instance_termination = false
  metadata_imdsv2_required     = true
  allow_upload_download        = true
  management_server            = "CP-Management-gwlb-tf"
  configuration_template       = "gwlb-configuration"
  admin_shell                  = "/etc/cli.sh"

  // --- Gateway Load Balancer Configuration ---
  gateway_load_balancer_name       = "gwlb1"
  target_group_name                = "cp-tg1"
  enable_cross_zone_load_balancing = "true"

  // --- Check Point CloudGuard IaaS Security Gateways Auto Scaling Group Configuration ---
  gateway_name                           = "Check-Point-GW-tf"
  gateway_instance_type                  = "r5.large"
  minimum_group_size                     = 2
  maximum_group_size                     = 5
  gateway_version                        = "R81.20-BYOL"
  gateway_password_hash                  = ""
  gateway_maintenance_mode_password_hash = "" # For R81.10 and below the gateway_password_hash is used also as maintenance-mode password.
  gateway_SICKey                         = "Bii8odHl"
  gateways_provision_address_type        = "private"
  allocate_public_IP                     = false
  enable_cloudwatch                      = false
  gateway_bootstrap_script               = "echo 'this is bootstrap script' > /home/admin/bootstrap.txt"

  // --- Check Point CloudGuard IaaS Security Management Server Configuration ---
  management_deploy                         = true
  management_instance_type                  = "m5.xlarge"
  management_version                        = "R81.20-BYOL"
  management_password_hash                  = ""
  management_maintenance_mode_password_hash = "" # For R81.10 and below the management_password_hash is used also as maintenance-mode password.
  gateways_policy                           = "Standard"
  gateway_management                        = "Locally managed"
  admin_cidr                                = "10.0.0.0/8"
  gateways_addresses                        = "100.65.0.0/16"

  // --- Other parameters ---
  volume_type = "gp3"

  tgw_id = "tgw-0430826c231550bf5"
  
}