resource "aws_lb" "test-alb" {
  count                      = var.create_load_balancer ? 1 : 0
  name                       = var.load_balancer_name
  internal                   = false
  load_balancer_type         = var.load_balancer_type
  security_groups            = [aws_security_group.cloudfront_to_ec2.id]
  subnets                    = aws_subnet.public_subnets[*].id
  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}
