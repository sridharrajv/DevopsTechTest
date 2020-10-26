data "aws_caller_identity" "current" {}

data "aws_availability_zones" "zones" {}

data "aws_ami" "amazon_linux" {
  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-2.0.20180810-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
}