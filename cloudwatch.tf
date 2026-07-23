# SNS Topic for alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.environment}-alarms-topic"
}

# Email subscription (you'll need to confirm via email)
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email  # define this variable in variables.tf
}

resource "aws_cloudwatch_metric_alarm" "asg_instance_health" {
  alarm_name          = "${var.environment}-asg-instance-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "An instance in the ASG is failing EC2 status checks"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }

  # Only send notification when the alarm triggers (ALARM state)
  alarm_actions = [aws_sns_topic.alarms.arn]
  # No ok_actions -> you won't receive "OK" emails
}

resource "aws_cloudwatch_dashboard" "asg_health_dashboard" {
  dashboard_name = "${var.environment}-asg-health"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/EC2", "StatusCheckFailed", { "AutoScalingGroupName" = aws_autoscaling_group.terraform_asg.name }]
          ]
          period = 60
          stat   = "Maximum"
          region = var.aws_region
          title  = "EC2 Status Check Failures (ASG)"
          view   = "timeSeries"
          stacked = false
        }
      },
      {
        type = "alarm"
        properties = {
          alarms = [aws_cloudwatch_metric_alarm.asg_instance_health.arn]
          title  = "ASG Instance Health Alarm State"
        }
      }
    ]
  })
}