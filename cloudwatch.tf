###########################
###### SNS FOR ALARMS #####
###########################

resource "aws_sns_topic" "alarms" {
  name = "${var.environment}-cloudwatch-alarms"
}

resource "aws_sns_topic_subscription" "alarms_email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

###########################
##### EC2 HEALTH CHECK ####
###########################

# Fires if any instance in the ASG fails EC2 status checks (system or

resource "aws_cloudwatch_metric_alarm" "asg_instance_health" {
  alarm_name          = "${var.environment}-asg-instance-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "An instance in the ASG is failing EC2 status checks"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }
  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}

# CPU ALERT 

# email when average CPU crosses the threshold.

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-asg-high-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_target_cpu
  alarm_description   = "ASG average CPU at or above ${var.asg_target_cpu}% for 2 minutes"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }
  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]
}
