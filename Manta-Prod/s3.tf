resource "aws_s3_bucket" "s3-bucket" {
  for_each = var.create_s3_bucket && var.s3_bucket_names != null ? toset(var.s3_bucket_names) : []

  bucket = each.value

  tags = {
    Name = each.value

  }
}
