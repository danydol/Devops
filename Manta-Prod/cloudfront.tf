# Create the OAC (modern security)
resource "aws_cloudfront_origin_access_control" "default" {
  count                             = var.create_distribution ? 1 : 0
  name                              = "oac-for-backups"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Create the CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.create_distribution ? 1 : 0
  origin {
    # Using the domain name from our data source
    domain_name              = aws_s3_bucket.cloudfront-bucket[count.index].bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.default[count.index].id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


resource "aws_s3_bucket_policy" "allow_cloudfront" {
  count  = var.create_distribution ? 1 : 0
  bucket = aws_s3_bucket.cloudfront-bucket[count.index].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Sid    = "AllowCloudFrontReadOnly"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.cloudfront-bucket[count.index].arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution[count.index].arn
        }
      }
    }
  })
}

resource "aws_s3_bucket" "cloudfront-bucket" {
  count = var.create_distribution ? 1 : 0

  bucket = "sasdjalj3rq3rkkwewqklwqeklqweqwrnwqmsdfsdf"

  tags = {
    Name = "bucket1"
  }
}
