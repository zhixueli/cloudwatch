locals {
  thresholds = {
    CPUUtilizationThreshold   = 50
  }
}

// Topic to receive CloudWatch alarms and send notifications to given subscriptions (emails/sms/lambda/http)
resource "aws_sns_topic" "default" {
  name_prefix = "ec2-alerts"

  // Terraform doesn’t allow creating email subscriptions, so we have to use a provisioner instead.
  // This code runs on your local machine, and uses your local AWS CLI to create the email subscription. 
  // Once you run this, you’ll have to open your email and confirm the subscription creation.
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${self.arn} --protocol email --notification-endpoint ${var.alarms_email} --region ${var.region}"
  }
}

// Create the CloudWatch alarms for each EC2 instance.
// You could create more alarms for specific metrics 
// on the same SNS topics (in alarm_actions below)
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_too_low" {
  count               = "${var.instance_count}"
  alarm_name          = "cpu_too_low_${element(aws_instance.server.*.id, count.index)}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "cpu_usage_user"    // the metric name must be same as the metrics collected in cw_agent_template json file
  namespace           = "Server"            // namespace must be same as the namespace in the "metrics" section of cw_agent_template json file
  period              = "600"
  statistic           = "Average"
  threshold           = "${local.thresholds["CPUUtilizationThreshold"]}"
  alarm_description   = "Average CPU utilization over last 10 minutes too low"
  alarm_actions       = ["${aws_sns_topic.default.arn}"]

  dimensions = {
    InstanceId = "${element(aws_instance.server.*.id, count.index)}"
  }
}

// Uncomment this to enable sms notifications
/*
resource "aws_sns_topic_subscription" "topic_sms" {
  topic_arn = "${aws_sns_topic.default.arn}"
  protocol  = "sms"
  endpoint  = "${var.alarms_phone}"
}
*/