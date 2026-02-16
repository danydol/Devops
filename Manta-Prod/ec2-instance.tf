locals {
  # Creates a map where { "name" = "sg-id" }
  sg_lookup = { for name, sg in data.aws_security_group.individual : name => sg.id }
   # data.aws_security_group.individual[sg].name => sg 
  }




resource "aws_instance" "app-server" {
  # Iterates over the map defined in your variables
  for_each = var.ec2_configs

  ami           = each.value.ami_id
  instance_type = each.value.instance_type

  # Pulls the specific subnet ID from your data source using the index provided in the map
  subnet_id = aws_subnet.private_subnets[each.value.subnet_index].id

  availability_zone           = local.availability_zone
  disable_api_termination     = local.disable_api_termination
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = local.associate_public_ip_address
  vpc_security_group_ids = [for name in each.value.security_group_list : local.sg_lookup[name]]



  tags = {
    Name = each.value.instance_name
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    delete_on_termination = true
    volume_size           = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
  }

  ebs_block_device {
    delete_on_termination = true
    device_name           = each.value.second_volume_name
    volume_size           = each.value.second_volume_size
    volume_type           = each.value.second_volume_type
  }
}