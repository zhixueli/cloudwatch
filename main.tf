terraform {
  backend "s3" {
    bucket = "zhixue.terraform"
    key    = "cloudwatch/terraform.tfstate"
    region = "${var.region}"
  }
}

provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region     = "${var.region}"
}