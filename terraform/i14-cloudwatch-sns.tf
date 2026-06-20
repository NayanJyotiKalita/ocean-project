#-------ALERTS--------

## SNS - Topic
resource "aws_sns_topic" "ocean_sns_topic" {
  name = "ocean-alerts-${random_pet.random.id}"
}

## SNS - Subscription
resource "aws_sns_topic_subscription" "ocean_sns_topic_subscription" {
  topic_arn = aws_sns_topic.ocean_sns_topic.arn
  protocol  = "email"
  endpoint  = "ocean-devops@gmail.com"
}

#--------CLOUDWATCH-------
resource "aws_cloudwatch_log_group" "company_logs" {
  name              = "/aws/ec2/company-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "bureau_logs" {
  name              = "/aws/ec2/bureau-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "employee_logs" {
  name              = "/aws/ec2/employee-app"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "rds_logs" {
  name              = "/aws/rds/instance/${aws_db_instance.rds_db.identifier}/postgresql"
  retention_in_days = 30
}

#-------EC2 CPU Alarms--------
## Company App Alarm
resource "aws_cloudwatch_metric_alarm" "company_cpu_alarm" {
  for_each                  = module.ec2_private_app1            
  alarm_name                = "company-high-cpu-utilization-alarm-${each.key}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"

  # A buffer time of 10 minutes
  period                    = 300
  evaluation_periods        = 2

  statistic                 = "Average"
  threshold                 = 80          # Alert if CPU averages over 80% for 10 minutes
  alarm_description         = "The alarm is triggered when CPU >= 80%"
  alarm_actions             = [aws_sns_topic.ocean_sns_topic.arn]

  dimensions = {
    InstanceId = each.value.id 
  }
}

## Bureau App Alarm
resource "aws_cloudwatch_metric_alarm" "bureau_cpu_alarm" {
  for_each                  = module.ec2_private_app2            
  alarm_name                = "bureau-high-cpu-utilization-alarm-${each.key}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"

  # A buffer time of 10 minutes
  period                    = 300
  evaluation_periods        = 2

  statistic                 = "Average"
  threshold                 = 80          # Alert if CPU averages over 80% for 10 minutes
  alarm_description         = "The alarm is triggered when CPU >= 80%"
  alarm_actions             = [aws_sns_topic.ocean_sns_topic.arn]

  dimensions = {
    InstanceId = each.value.id 
  }
}

## Employee App Alarm
resource "aws_cloudwatch_metric_alarm" "employee_cpu_alarm" {
  for_each                  = module.ec2_private_app3            
  alarm_name                = "employee-high-cpu-utilization-alarm-${each.key}"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"

  # A buffer time of 10 minutes
  period                    = 300
  evaluation_periods        = 2

  statistic                 = "Average"
  threshold                 = 80          # Alert if CPU averages over 80% for 10 minutes
  alarm_description         = "The alarm is triggered when CPU >= 80%"
  alarm_actions             = [aws_sns_topic.ocean_sns_topic.arn]

  dimensions = {
    InstanceId = each.value.id 
  }
}

#-------RDS Alarms--------
resource "aws_cloudwatch_metric_alarm" "rds_connection_alarm" {        
  alarm_name                = "rds-high-connection-alarm"
  comparison_operator       = "GreaterThanThreshold"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"

  # A buffer time of 5 minutes
  period                    = 300
  evaluation_periods        = 1

  statistic                 = "Average"
  threshold                 = 60          
  alarm_description         = "The alarm is triggered when RDS connection > 60"
  alarm_actions             = [aws_sns_topic.ocean_sns_topic.arn]

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.rds-db.identifier
  }
}

