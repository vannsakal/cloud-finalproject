# This is just the virtual firewall rules attach to EC2 instances

resource "aws_security_group" "asg_sg" {
  name        = "${var.environment}-asg-security-group"
  description = "Allow traffic for the Auto Scaling Group instances"
  vpc_id      = aws_vpc.main.id
  depends_on  = [aws_vpc.main]
}

# Allow inbound HTTP for EC2 instances

resource "aws_security_group_rule" "allow_http_in" {

  description              = "Allow inbount HTTP traffic"
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id # this tells EC2 to only accept traffic coming from our Load Balancer
  security_group_id        = aws_security_group.asg_sg.id # ID of our asg_sg

}

# Allow all outbound traffic

resource "aws_security_group_rule" "allow_all_out" {

  description       = "Allow outbound traffic"
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.asg_sg.id

}
