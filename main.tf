provider "aws" {
  alias = "west"

  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"

  region = "us-west-2"
}

module "vpc" {
  source = "./modules/vpc"

  name = "derp-vpc"
  cidr = "10.1.0.0/16"

  public_subnets = "10.1.0.0/19,10.1.64.0/19,10.1.128.0/19"
  private_subnets = "10.1.32.0/19,10.1.96.0/19,10.1.160.0/19"
  az_names = "us-west-2a,us-west-2b,us-west-2c"

  aws_provider = "aws.west"

  nat_instance_size = "t2.small"
  nat_ami = "ami-290f4119"
}
