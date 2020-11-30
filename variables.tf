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