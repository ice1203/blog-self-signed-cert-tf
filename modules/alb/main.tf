## security group for elb
resource "aws_security_group" "main_elb" {
  name        = "${var.prefix}-elb"
  description = "${var.prefix}-elb"
  vpc_id      = var.vpc_id
}

#trivy:ignore:AVD-AWS-0104
resource "aws_vpc_security_group_egress_rule" "main_elb" {
  for_each          = var.elb_security_group_rules.main_elb.outbound_rules
  security_group_id = aws_security_group.main_elb.id

  cidr_ipv4   = each.value.cidr_ipv4
  from_port   = each.value.from_port
  ip_protocol = each.value.ip_protocol
  to_port     = each.value.to_port
}
resource "aws_vpc_security_group_ingress_rule" "main_elb" {
  for_each          = var.elb_security_group_rules.main_elb.inbound_rules
  security_group_id = aws_security_group.main_elb.id

  cidr_ipv4      = each.value.cidr_ipv4
  prefix_list_id = each.value.prefix_list_id
  from_port      = each.value.from_port
  ip_protocol    = each.value.ip_protocol
  to_port        = each.value.to_port
}

#trivy:ignore:AVD-AWS-0053
resource "aws_lb" "main" {
  name                       = "${var.prefix}-elb"
  internal                   = true
  security_groups            = [aws_security_group.main_elb.id]
  load_balancer_type         = "application"
  subnets                    = var.allocated_subnets
  drop_invalid_header_fields = true
  dynamic "access_logs" {
    for_each = var.elblog_bucket_name != "" ? [1] : []
    content {
      bucket  = var.elblog_bucket_name
      prefix  = "${var.prefix}-ALB"
      enabled = true
    }

  }
  tags = {
    Name = "${var.prefix}-elb"
  }
}


## ELB listener
resource "aws_lb_listener" "https_primary" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.cert_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Hello World"
      status_code  = "200"
    }
  }
}
