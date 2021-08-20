data "aws_ami" "default" {
  most_recent = true
  owners      = ["self"]
  filter {
    name = "name"

    values = [
      "RStudioWorkbench*"
    ]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "rstudio-workbench-ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.19.0"

  instance_count = 1

  name                        = "RStudio Workbench"
  ami                         = data.aws_ami.default.id
  instance_type               = "t2.large	"
  subnet_ids                  = module.vpc.public_subnets
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.auth.id

  root_block_device = [
    {
      delete_on_termination = true
      device_name           = "/dev/sda1"
      encrypted             = true
      volume_size           = 180
      volume_type           = "gp2"
    }
  ]
}
