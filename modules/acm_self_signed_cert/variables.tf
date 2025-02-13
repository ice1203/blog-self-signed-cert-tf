variable "env" {
  description = "The environment in which the resources are created"
  type        = string

}
variable "server" {
  description = "Server certificate information"
  type = object({
    subject = object({
      common_name  = string
      organization = string
      country      = string
      province     = string
    })
    validity_period_hours = number
  })

}
variable "root_ca" {
  description = "Root CA certificate information"
  type = object({
    subject = object({
      common_name  = string
      organization = string
      country      = string
      province     = string
    })
    validity_period_hours = number
  })

}
