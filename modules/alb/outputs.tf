output "elb_security_group_id" {
  value       = aws_security_group.main_elb.id
  description = "value of security group id"
}
output "elb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "value of zone id"
}
output "elb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "value of dns name"
}
