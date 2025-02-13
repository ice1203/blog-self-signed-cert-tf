output "acm_cert_arn" {
  description = "ACMにインポートした自己署名証明書のARN"
  value       = aws_acm_certificate.main.arn
}
