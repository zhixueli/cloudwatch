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
    default = "someone@bytedance.com"
}

variable "alarms_phone" {
    default = "+8613800000000"
}

variable "ami" {
    default = "ami-00ed269ce8acd7fff"
}

variable "keypair" {
    default = "uw1-kp"
}