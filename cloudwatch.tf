###########################
####### CLOUDWATCH ########
###########################

# ---------------------------------------------------------
# Log Group - application logs (nginx access/error) shipped
# from each EC2 instance via the CloudWatch Agent
# ---------------------------------------------------------

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/ec2/${var.environment}/webapp"
  retention_in_days = 14

  tags = {
    Name = "${var.environment}-webapp-logs"
  }
}

# ---------------------------------------------------------
# Allow EC2 instances (via ssm_role, already attached to
# ssm_profile in iam.tf) to push metrics/logs to CloudWatch
# ---------------------------------------------------------

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ---------------------------------------------------------
# Auto Scaling Policies - referenced by the alarms below
# ---------------------------------------------------------

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.environment}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.terraform_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.environment}-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 120
  autoscaling_group_name = aws_autoscaling_group.terraform_asg.name
}

# ---------------------------------------------------------
# Alarms - watch average CPU across the ASG
# ---------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Average CPU > 70% for 2 periods -> scale out"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20
  alarm_description   = "Average CPU < 20% for 2 periods -> scale in"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}

# ---------------------------------------------------------
# Alarm - unhealthy hosts behind the ALB target group
# (good evidence for "simulate failure -> auto recovery")
# ---------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.environment}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more targets failing health checks behind the ALB"

  dimensions = {
    TargetGroup  = aws_lb_target_group.reverse_proxy.arn_suffix
    LoadBalancer = aws_lb.web_alb.arn_suffix
  }
}

# ---------------------------------------------------------
# Dashboard - CPU, request count, and healthy/unhealthy hosts
# ---------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-webapp-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ASG - Average CPU Utilization"
          region  = var.aws_region
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.terraform_asg.name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "ALB - Request Count"
          region  = var.aws_region
          period  = 60
          stat    = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web_alb.arn_suffix]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB - Healthy vs Unhealthy Hosts"
          region  = var.aws_region
          period  = 60
          stat    = "Average"
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.reverse_proxy.arn_suffix, "LoadBalancer", aws_lb.web_alb.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.reverse_proxy.arn_suffix, "LoadBalancer", aws_lb.web_alb.arn_suffix]
          ]
        }
      }
    ]
  })
}
