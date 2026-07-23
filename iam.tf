# IAM Role for EC2 to use Systems Manager
resource "aws_iam_role" "ssm_role" {
  name = "${var.environment}-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.environment}-ssm-role"
  }
}

# Attach AWS managed SSM policy
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile (required to attach role to EC2)
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.environment}-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}


# Custom IAM policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.environment}-ec2-s3-policy"
  description = "Allow EC2 to read/write to the app S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Attach the S3 policy to the existing EC2 IAM role
resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}