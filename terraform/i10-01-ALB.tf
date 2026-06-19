module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "10.5.0"

  name               = "${local.name}-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.alb.id]

  # For example only
  enable_deletion_protection = false

  # Listeners
  listeners = {
    # Listener-1: my-http-https-redirect
    my-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    my-https-listener = {
      port                        = 443
      protocol                    = "HTTPS"
      ssl_policy                  = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
      certificate_arn             = module.acm.acm_certificate_arn

      # Fixed Response for Root Context
      fixed_response = {
        content_type = "text/plain"
        message_body = "Welcome to Ocean Across"
        status_code  = "200"
      }# End of Fixed Response

      # Load Balancer Rules
      rules = {
        # Rule-1: myapp1-rule
        app1-rule = {
          actions = [{
            weighted_forward = {
              target_groups = [
                {
                  target_group_key = "mytg"
                  weight           = 1
                }
              ]
              stickiness = {
                enabled  = true
                duration = 3600
              }
            }
          }]
          conditions = [
            {
              path_pattern = {
                values = ["/*"]
              }
            }
          ]
        } # End of app1-rule # End of my-http-80-listener
      } # End of Rules Block 
    } # End of my-http-listener block
  }  # End of listeners block
  
  # Target Groups
  target_groups = {
    mytg = {
      # VERY IMPORTANT: We will create aws_lb_target_group_attachment resource separately when we use create_attachment = false
      create_attachment = false
      name_prefix                       = "mytg-"
      protocol                          = "HTTP"
      port                              = 80
      target_type                       = "instance"
      deregistration_delay              = 10
      load_balancing_cross_zone_enabled = false
      protocol_version = "HTTP1"

      health_check = {
        enabled             = true
        interval            = 30
        path                = "/app/index.html"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      } # End of health_check Block
      tags = local.common_tags  # target_group tags
    } # End of taget_groups Block
  }
  tags = local.common_tags  # ALB Tags
}
