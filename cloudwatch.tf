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

# Fires if any instance in the ASG fails EC2 status checks (system or instance level) -- this is the same signal the ASG uses to know an 
#instance is unhealthy and needs replacing
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

###########################
###### DYNAMIC SCALING ####
###########################
# Explicit step-scaling policies so the same CloudWatch alarm can both
# notify SNS and tell the ASG to add/remove an instance.

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.environment}-asg-scale-out"
  autoscaling_group_name = aws_autoscaling_group.terraform_asg.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 120
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.environment}-asg-scale-in"
  autoscaling_group_name = aws_autoscaling_group.terraform_asg.name
  policy_type            = "SimpleScaling"
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 120
}

# Average CPU across the ASG crosses above the threshold (50% by default)
# -> spawn one more instance AND email notification_email
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
  alarm_actions = [aws_autoscaling_policy.scale_out.arn, aws_sns_topic.alarms.arn]
}

# Average CPU drops well below the threshold -> remove an instance AND
# email notification_email. Without this, the ASG only ever grows.
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-asg-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = var.asg_target_cpu / 2
  alarm_description   = "ASG average CPU below ${var.asg_target_cpu / 2}% for 3 minutes"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in.arn, aws_sns_topic.alarms.arn]
}
