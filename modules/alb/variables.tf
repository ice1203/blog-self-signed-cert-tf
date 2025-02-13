variable "prefix" {
  type        = string
  description = "resource name prefix"
}
variable "vpc_id" {
  type        = string
  description = "vpc id"

}
variable "cert_arn" {
  type        = string
  description = "certificate arn"

}
variable "allocated_subnets" {
  type        = list(string)
  description = "public subnets"

}
variable "elblog_bucket_name" {
  type        = string
  description = "elb log bucket name"
  default     = ""

}

variable "elb_security_group_rules" {
  type = object({
    main_elb = object({
      inbound_rules = map(object({
        from_port      = number
        to_port        = number
        ip_protocol    = string
        cidr_ipv4      = string
        prefix_list_id = string
      }))
      outbound_rules = map(object({
        from_port   = number
        to_port     = number
        ip_protocol = string
        cidr_ipv4   = string
      }))
    })
    }
  )
  description = "elb security group rules"

}
