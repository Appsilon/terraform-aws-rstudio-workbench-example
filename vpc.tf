locals {
  vpc_name = "vpc-rstudio"
  vpc_cidr = "10.4.0.0/16"
  region = "eu-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.6.0"

  name = local.vpc_name
  cidr = local.vpc_cidr

  azs             = formatlist(format("%s%%s", local.region), ["a", "b"])
  private_subnets = ["${cidrsubnet(local.vpc_cidr, 3, 0)}", "${cidrsubnet(local.vpc_cidr, 3, 2)}"]
  public_subnets  = ["${cidrsubnet(local.vpc_cidr, 4, 2)}", "${cidrsubnet(local.vpc_cidr, 4, 6)}"]

  manage_default_security_group  = true
  default_security_group_ingress = [{}]
  default_security_group_egress  = [{}]
}
