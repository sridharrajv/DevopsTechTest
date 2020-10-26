data "template_file" "user_data" {

  template = file("user_data.sh")

  vars = {
    sshpubkey = var.sshpubkey
  }
}

module "autoscaling" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = var.name

  image_id = data.aws_ami.amazon_linux.id

  instance_type = var.instance_type

  root_block_device = [
    {
      volume_size = 8
      volume_type = "gp2"
      # encrypted = "" # Should be encrypted but not for this demo
    }
  ]

  security_groups = [module.security_group_ec2.this_security_group_id]
  asg_name = var.name

  vpc_zone_identifier = module.vpc.private_subnets
  health_check_type = "EC2"
  desired_capacity = 2
  max_size         = 10
  min_size         = 2

  tags_as_map = var.tags
}

resource "aws_autoscaling_attachment" "alb" {
  autoscaling_group_name = module.autoscaling.this_autoscaling_group_id
  alb_target_group_arn   = module.alb.target_group_arns[0]
}