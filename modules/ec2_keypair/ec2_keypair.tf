
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}


resource "aws_key_pair" "ec2_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.private_key.public_key_openssh
}
