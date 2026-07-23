###########################
##### RDS SUBNET GROUP ####
###########################

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id] # RDS lives in private subnets, no route to IGW

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

###########################
###### RDS SECURITY  ######
###########################

resource "aws_security_group" "db_sg" {
  name        = "${var.environment}-db-sg"
  description = "Allow MySQL only from the app instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from ASG instances only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id] # nothing else on the network can reach the db
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-db-sg"
  }
}

###########################
######## DB PASSWORD ######
###########################

resource "random_password" "db_password" {
  length  = 20
  special = false # avoids characters that need escaping in connection strings / env files
}

###########################
###### RDS INSTANCE #######
###########################

resource "aws_db_instance" "app_db" {
  identifier     = "${var.environment}-app-db"
  engine         = "mysql"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true # encryption at rest, security rubric line

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  multi_az             = false # single-AZ to keep this within free-tier/lab budget; call out as a prod recommendation in the report
  publicly_accessible  = false # no public IP, only reachable from inside the VPC
  skip_final_snapshot  = true  # fine for a lab project, would be false in production
  deletion_protection  = false
  backup_retention_period = 1

  tags = {
    Name = "${var.environment}-app-db"
  }
}

###########################
##### SECRETS MANAGER #####
###########################
# Stores DB creds so they never sit in plaintext in Terraform state outputs or the AMI/user_data

resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.environment}-app-db-credentials"
  recovery_window_in_days = 0 # lab project: allow immediate deletion instead of a recovery window, so destroy/apply cycles don't collide on the name
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    host     = aws_db_instance.app_db.address
    port     = aws_db_instance.app_db.port
    username = var.db_username
    password = random_password.db_password.result
    dbname   = var.db_name
  })
}
