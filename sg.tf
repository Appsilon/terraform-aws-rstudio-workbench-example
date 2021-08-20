module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.3.0"

  name        = "rstudio-workbench-sg"
  description = "Security group for usage with Rstudio Workbench EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "ssh-tcp", "all-icmp"]

  ingress_with_cidr_blocks = [
    {
      from_port   = 8787
      to_port     = 8787
      protocol    = "tcp"
      description = "User-service ports (ipv4)"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  egress_rules = ["all-all"]
}
