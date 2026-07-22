###########################
##### CLOUDWATCH LOGS ######
###########################
# nginx access/error + gunicorn error logs land here (see server_setup.sh.tpl / CW agent config)

resource "aws_cloudwatch_log_group" "webapp_logs" {
  name              = "/${var.environment}/webapp"
  retention_in_days = 14

  tags = {
    Name = "${var.environment}-webapp-logs"
  }
}

###########################
##### SCALING POLICY ######
###########################
# Target tracking scaling driven by the ASGAverageCPUUtilization CloudWatch metric -
# this is what actually makes "Auto Scaling" happen, not just the min/max/desired numbers

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.environment}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.terraform_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}

###########################
######## SNS TOPIC ########
###########################

resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-cloudwatch-alerts"
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

###########################
######## ALARMS ###########
###########################

# Sustained high CPU across the ASG
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.environment}-asg-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "CPUUtilization"
  namespace            = "AWS/EC2"
  period               = 60
  statistic            = "Average"
  threshold            = 70
  alarm_description    = "Average CPU across the ASG has been above 70% for 2 minutes"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.terraform_asg.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Catches EC2 instance failure / recovery behind the ALB - this is the alarm to screenshot
# alongside your simulated-failure deliverable
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.environment}-alb-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name          = "UnHealthyHostCount"
  namespace            = "AWS/ApplicationELB"
  period               = 60
  statistic            = "Average"
  threshold            = 0
  alarm_description    = "One or more targets behind the ALB are unhealthy"

  dimensions = {
    TargetGroup  = aws_lb_target_group.reverse_proxy.arn_suffix
    LoadBalancer = aws_lb.web_alb.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# RDS running low on disk
resource "aws_cloudwatch_metric_alarm" "rds_low_storage" {
  alarm_name          = "${var.environment}-rds-low-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods   = 1
  metric_name          = "FreeStorageSpace"
  namespace            = "AWS/RDS"
  period               = 300
  statistic             = "Average"
  threshold             = 2000000000 # 2 GB in bytes
  alarm_description     = "RDS free storage has dropped below 2 GB"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.app_db.id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

###########################
####### DASHBOARD #########
###########################

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.environment}-cloud-finalproject"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title  = "ASG Average CPU Utilization"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.terraform_asg.name]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "ASG In-Service Instances"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.terraform_asg.name]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title  = "ALB Healthy / Unhealthy Hosts"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.reverse_proxy.arn_suffix, "LoadBalancer", aws_lb.web_alb.arn_suffix],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", aws_lb_target_group.reverse_proxy.arn_suffix, "LoadBalancer", aws_lb.web_alb.arn_suffix]
          ]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "ALB Requests / 5xx Errors"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web_alb.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.web_alb.arn_suffix]
          ]
        }
      },
      {
        type = "metric", x = 0, y = 12, width = 12, height = 6
        properties = {
          title  = "RDS CPU / Connections"
          view   = "timeSeries"
          region = var.aws_region
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.app_db.id],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.app_db.id]
          ]
        }
      }
    ]
  })
}
