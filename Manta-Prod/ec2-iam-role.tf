# Create an IAM role for SSM
resource "aws_iam_role" "ssm_role" {
  name = local.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = local.assume_role_principal
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  max_session_duration = 14000
}

# <--- Keep this empty line at the end of your file

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_managed_policy_attachment" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# # Create an instance profile for the SSM role (if needed for EC2)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = local.iam_instance_profile_name
  role = aws_iam_role.ssm_role.name
}
