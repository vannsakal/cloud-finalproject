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

# Lets the instance push logs/metrics to CloudWatch via the CloudWatch agent
resource "aws_iam_role_policy_attachment" "cw_agent_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Least-privilege inline policy: only the app artifact in S3, only this one DB secret
resource "aws_iam_role_policy" "webapp_deploy_access" {
  name = "${var.environment}-webapp-deploy-access"
  role = aws_iam_role.ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadAppArtifact"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.secure_bucket.arn}/artifacts/*"
      },
      {
        Sid      = "ReadDbSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.db_secret.arn
      }
    ]
  })
}

# Instance Profile (required to attach role to EC2)
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.environment}-ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}