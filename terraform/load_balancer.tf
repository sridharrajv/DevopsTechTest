#
# Demo
#
# Simple Web App ALB Infrastructure
#

module "alb" {

  source = "terraform-aws-modules/alb/aws"

  version = "~> 5.0"

  name = var.name

  load_balancer_type = "application"

  vpc_id = module.vpc.vpc_id

  subnets = module.vpc.public_subnets

  security_groups = [module.security_group_alb.this_security_group_id]

  listener_ssl_policy_default = "ELBSecurityPolicy-TLS-1-2-2017-01"

  access_logs = {
    enabled = true
    bucket  = aws_s3_bucket.logs.bucket
    prefix  = "alb"
  }

  target_groups = [{
    backend_port     = "80"
    backend_protocol = "HTTP" # Should HTTPS but this is a demo
    target_type      = "instance"
    health_check = {
      enabled             = true
      healthy_threshold   = 5
      interval            = 30
      matcher             = "200"
      path                = "/"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 2
    }
  }]

  https_listeners = [{
    port            = 443
    protocol        = "HTTPS"
    certificate_arn = module.ssl_cert.acm_arn
  }]

  http_tcp_listeners = [
    {
      port        = 80
      protocol    = "HTTP"
      action_type = "redirect"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  ]

  tags = var.tags
}