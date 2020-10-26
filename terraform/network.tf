module "vpc" {
  name   = var.name
  source = "terraform-aws-modules/vpc/aws"

  cidr = var.vpc_cidr

  azs = [
    data.aws_availability_zones.zones.names[0],
    data.aws_availability_zones.zones.names[1],
  ]

  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  database_subnets = var.database_subnets

  create_database_subnet_group = true
  enable_nat_gateway           = true
  single_nat_gateway           = true # Demo

  tags = var.tags
}

module "security_group_alb" {

  source = "terraform-aws-modules/security-group/aws"

  version = "~> 3.16"

  name = format("%s-alb-webserver", var.name)

  description = "Security group for ${var.name} ALB"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

module "security_group_ec2" {

  source = "terraform-aws-modules/security-group/aws"

  version = "~> 3.16"

  name = format("%s-ec2-webserver", var.name)

  description = "Security group for ${var.name} EC2"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = [var.vpc_cidr]
  ingress_rules       = ["http-80-tcp", "all-icmp"] # We need SSH here too but not implemented for demo
  egress_rules        = ["all-all"]

  tags = var.tags
}

module "security_group_db" {

  source = "terraform-aws-modules/security-group/aws"

  version = "~> 3.16"

  name = format("%s-db", var.name)

  description = "Security group for ${var.name} DB"

  vpc_id = module.vpc.vpc_id

  ingress_cidr_blocks = var.private_subnets
  ingress_rules       = ["mysql-tcp"]

  tags = var.tags
}