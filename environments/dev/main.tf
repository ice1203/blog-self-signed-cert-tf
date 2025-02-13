locals {
  env    = "dev"
  system = "selfsigned"
  # tflint-ignore: terraform_unused_declarations
  prefix = "${local.system}-${local.env}"
  domain = "selfsigned.example.com"
  # tflint-ignore: terraform_unused_declarations
  tags = {
    "ManagedBy"   = "Terraform"
    "Environment" = local.env
    "System"      = local.system
  }
}

module "main_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${local.prefix}-vpc"
  cidr = "172.18.0.0/16"

  azs             = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
  private_subnets = ["172.18.0.0/24", "172.18.1.0/24", "172.18.2.0/24"]
  public_subnets  = ["172.18.128.0/24", "172.18.129.0/24", "172.18.130.0/24"]
  intra_subnets   = ["172.18.131.0/24", "172.18.132.0/24", "172.18.133.0/24"]

  enable_nat_gateway                   = false
  single_nat_gateway                   = false
  enable_vpn_gateway                   = false
  enable_dns_hostnames                 = true
  manage_default_network_acl           = true
  enable_flow_log                      = false
  flow_log_max_aggregation_interval    = 60
  create_flow_log_cloudwatch_iam_role  = true
  create_flow_log_cloudwatch_log_group = true
  public_dedicated_network_acl         = true

  tags = merge(local.tags, {
    Endpoint = "true"
  })
}

# current reagion
data "aws_region" "current" {}

# route53 private hosted zone
resource "aws_route53_zone" "private" {
  name = "example.com"
  vpc {
    vpc_id     = module.main_vpc.vpc_id
    vpc_region = data.aws_region.current.name
  }
  tags = merge(local.tags, {
    Name = "example.com"
  })
}

module "acm_self_signed_cert" {
  source = "../../modules/acm_self_signed_cert"

  env = local.env
  root_ca = {
    subject = {
      common_name  = "root"
      organization = "mycorp."
      country      = "JP"
      province     = "Tokyo"
    }
    validity_period_hours = 87600
  }
  server = {
    subject = {
      common_name  = local.domain
      organization = "mycorp."
      country      = "JP"
      province     = "Tokyo"
    }
    validity_period_hours = 8760
  }
}
module "alb" {
  source = "../../modules/alb"

  prefix            = local.prefix
  vpc_id            = module.main_vpc.vpc_id
  cert_arn          = module.acm_self_signed_cert.acm_cert_arn
  allocated_subnets = module.main_vpc.private_subnets
  elb_security_group_rules = {
    main_elb = {
      inbound_rules = {
        https_vpc = {
          from_port      = 443
          to_port        = 443
          ip_protocol    = "tcp"
          cidr_ipv4      = module.main_vpc.vpc_cidr_block
          prefix_list_id = null
        }
      }
      outbound_rules = {
        all = {
          from_port   = -1
          to_port     = -1
          ip_protocol = "-1"
          cidr_ipv4   = "0.0.0.0/0"
        }
      }
    }
  }

}

# route53 record A ailias
resource "aws_route53_record" "this" {
  zone_id = aws_route53_zone.private.zone_id
  name    = local.domain
  type    = "A"

  alias {
    name                   = module.alb.elb_dns_name
    zone_id                = module.alb.elb_zone_id
    evaluate_target_health = true
  }

}
