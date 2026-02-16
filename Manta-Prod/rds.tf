resource "aws_db_instance" "default" {
  count                         = var.create_db_instance ? 1 : 0
  db_subnet_group_name          = aws_db_subnet_group.db-subnet-group.name
  allocated_storage             = var.allocated_storage
  storage_type                  = var.storage_type
  engine                        = var.rds_engine
  identifier                    = var.identifier
  parameter_group_name          = var.parameter_group_name
  instance_class                = var.instance_class
  username                      = var.db_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.arn
  storage_encrypted             = true
  skip_final_snapshot           = true # Set to false for production to prevent data loss
}

# This creates the physical KMS key
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS storage and secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "rds-kms-key"
  }
}

# (Optional) This creates a friendly name for the key in the AWS Console
resource "aws_kms_alias" "rds" {
  name          = "alias/rds-key"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name       = "db-subnet-group"
  subnet_ids = aws_subnet.rds_subnets[*].id

  tags = {
    Name = "DB Subnet Group"
  }
}
