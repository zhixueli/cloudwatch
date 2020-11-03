locals {
    cw_agent_installer_url = "https://s3.amazonaws.com/amazoncloudwatch-agent/centos/amd64/latest/amazon-cloudwatch-agent.rpm"
    cw_agent_template_standard_url = "cw_agent_template_standard.json"
    cw_agent_template_advanced_url = "cw_agent_template_advanced.json"
}

// IAM role for EC2(running CloudWatch agent) to assume
resource "aws_iam_role" "ec2_cloudwatch" {
  name = "CloudWatchAgentRole"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_cloudwatch.json}"
  tags = {
    Name = "CloudWatchAgentRole"
  }
}

// Instance profile of IAM role
resource "aws_iam_instance_profile" "ec2_cloudwatch" {
  name = "CloudWatchAgentInstanceProfile"
  role  = "${aws_iam_role.ec2_cloudwatch.name}"
}

// IAM trust relationship policy of the created IAM role
data "aws_iam_policy_document" "ec2_cloudwatch" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "wildcard_cloudwatch_agent" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:PutMetricData",
      "ec2:DescribeVolumes",
      "ec2:DescribeTags",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]

    resources = ["*"]
  }
}

// IAM policy of the created IAM role
resource "aws_iam_role_policy" "wildcard_cloudwatch_agent" {
  name = "CloudWatchAgentRolePolicy"

  role   = "${aws_iam_role.ec2_cloudwatch.id}"
  policy = "${data.aws_iam_policy_document.wildcard_cloudwatch_agent.json}"
}

resource "aws_security_group" "ssh" {
  name        = "SSH"
  description = "SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server" {
  count                  = "${var.instance_count}"
  ami                    = "${var.ami}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.keypair}"
  iam_instance_profile   = "${aws_iam_instance_profile.ec2_cloudwatch.name}"
  vpc_security_group_ids = [ "${aws_security_group.ssh.id}" ]

  tags = {
    Name = "Server-${count.index + 1}"
  }

  // Copy CloudWatch agent config file from local to new created EC2 instance,
  // could use S3 to store the config file and use user data instead of provisoner
  // file and remote-exec to install and configure the agent
  provisioner "file" {

    connection {
      type = "ssh"
      user = "centos"
      private_key = "${file("~/Documents/SSH/uw1-kp.pem")}"
      timeout = "2m"
      agent = true
      host = "${self.public_dns}"
    }

    source      = "${local.cw_agent_installer_url}"
    destination = "${local.cw_agent_installer_url}"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "centos"
      private_key = "${file("~/Documents/SSH/uw1-kp.pem")}"
      timeout = "5m"
      agent = true
      host = "${self.public_dns}"
    }

    inline = [
        "curl -O ${local.cw_agent_installer_url}",
        "sudo rpm -U ./amazon-cloudwatch-agent.rpm",
        "sudo cp ${local.cw_agent_template_advanced_url} /opt/aws/amazon-cloudwatch-agent/bin/${local.cw_agent_template_advanced_url}",
        "cd /opt/aws/amazon-cloudwatch-agent/bin/",
        "sudo amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:${local.cw_agent_template_advanced_url} -s"
    ]
  }
  
}

output "server_public_dns" {
  value = "${aws_instance.server.*.public_dns}"
}
