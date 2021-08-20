data "aws_route53_zone" "default" {
  name = "your.domain.com"
}

resource "aws_route53_record" "public" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = "workbench.your.domain.com"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = false
  }
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.2.0"

  zone_id             = data.aws_route53_zone.default.zone_id
  domain_name         = "workbench.your.domain.com"
  wait_for_validation = true
}

resource "aws_lb" "main" {
  name            = "rstudio-workbench-alb"
  subnets         = module.vpc.public_subnets
  security_groups = [module.security_group.security_group_id]
}

resource "aws_lb_target_group" "rstudio" {
  name        = coalesce(format("rstudio-workbench-https"))
  port        = 8787
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = 8787
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 6
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  # Ensure the ALB exists before things start referencing this target group.
  depends_on = [aws_lb.main]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.id
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = module.acm.acm_certificate_arn

  default_action {
    target_group_arn = aws_lb_target_group.rstudio.id
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "main" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = module.acm.acm_certificate_arn
}

resource "aws_lb_target_group_attachment" "main" {
  count            = 1
  target_group_arn = aws_lb_target_group.rstudio.arn
  target_id        = element(module.ec2_instance.id, count.index)
  port             = 8787
}
