resource "aws_internet_gateway" "igw" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_tags
  }
}