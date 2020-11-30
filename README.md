## 在AWS启动EC2并自动化部署CloudWatch Agent以及SNS实现自定义指标监控和通知

本项目旨在以自动化的方式启动EC2实例，并同时部署CloudWatch Agent，启用CloudWatch Alarm以及SNS来监控自定义指标，并对异常情况发送通知

## 准备工作

* 本地运行terraform命令，请先配置好AWS AK/SK，并确保拥有足够的权限。另外需要预先创建好一个S3存储桶，用于保持terraform执行状态，并将存储桶名称配置于main.tf文件中

* template目录下为部署CloudWatch Agent所启用的监控指标模板，其中cw_agent_template_standard文件定义了最常用的指标，cw_agent_template_advanced文件涵盖了更全面的指标，可以根据具体情况自行修改

* variables.tf文件中定义了运行环境所需要的参数信息，请根据实际情况进行修改和替换
```
variable "region" {
    default = "us-west-1"
}

variable "instance_count" {
  default = "2"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "alarms_email" {
    default = "someone@contoso.com"
}

variable "alarms_phone" {
    default = "+123456789"
}

variable "ami" {
    default = "ami-00ed269ce8acd7fff"
}

variable "keypair" {
    default = "key_pair_name"
}
```
* 如需同时开启短信息通知，请在alarm.tf文件中配置启用

## 执行terraform创建资源
```
terraform init
terraform plan
terraform apply --auto-approve
```