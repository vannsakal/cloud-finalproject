# Application Load balancer

# load balancer security group, it has it's own firewall rules
# ALB sits on our public subnet to act as a reverse proxy for our EC2 webservers
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP inbound from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # egress to forward to anywhere on the internet, inluding our EC2
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.environment}-alb-sg"
  }
}

# Creating our Application Load Balancer

resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false # this set our alb to face the internet || public
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]                                 # without sg, it will dropped all traffic, that's why need the sg || sg means security group btw
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id] # placing it in 2 public subnets

  tags = {
    Name = "${var.environment}-web-alb"
  }

}

# Attach the listener to our ALB, then forward it

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn # attach the listener to the our ALB
  port              = 80                 # listen for http traffic
  protocol          = "HTTP"

  default_action {
    type             = "forward" # forward traffic to the group down below
    target_group_arn = aws_lb_target_group.reverse_proxy.arn
  }
}

# Target Group for the ASG instances, basically forward those HTTP we got, and send them to them bitch ah instances

resource "aws_lb_target_group" "reverse_proxy" {
  name     = "reverse-proxy"
  port     = 80 # forward traffic to EC2 on port 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id # ties our target group to our main VPC

  health_check {
    enabled             = true
    healthy_threshold   = 2   # check if instances reply 2 times in a row, it's gucci
    unhealthy_threshold = 2   # if not, hell nah, instances deead bruv
    timeout             = 5   # wait 5 seconds for reply, if nothing, boom, they gone bruv
    interval            = 30  # ping to our ec2 instances every 30 sec
    path                = "/" # just the root of our web lmao
  }

  tags = {
    Name = "${var.environment}-web-proxy"
  }
}


