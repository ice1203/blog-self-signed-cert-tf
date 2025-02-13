# ルート証明書（CA証明書）の作成
## PEM形式の秘密鍵の作成
resource "tls_private_key" "root_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

## PEM形式のTLS自己署名証明書の作成
resource "tls_self_signed_cert" "root_ca" {
  private_key_pem       = tls_private_key.root_ca.private_key_pem
  validity_period_hours = var.root_ca.validity_period_hours
  is_ca_certificate     = true # CA証明書を生成する場合はtrue

  subject {
    common_name  = var.root_ca.subject.common_name
    organization = var.root_ca.subject.organization
    country      = var.root_ca.subject.country
    province     = var.root_ca.subject.province
  }
  # 発行された証明書に許可されているキー使用法のリスト
  allowed_uses = [
    "cert_signing", # この証明書は他の証明書に署名するために使用できる
    "crl_signing",  # この証明書は証明書失効リスト（CRL）に署名するために使用できる
  ]
}

# エンド・エンティティ証明書（サーバー証明書）の作成
## PEM形式の秘密鍵の作成
resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

## PEM形式のCSR（証明書署名要求）の作成
resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem
  dns_names       = [var.server.subject.common_name] # サブジェクト代替名として追加するドメイン名のリスト

  subject {
    common_name  = var.server.subject.common_name
    organization = var.server.subject.organization
    country      = var.server.subject.country
    province     = var.server.subject.province
  }
}

## CSRを使用してPEM形式のTLS自己署名証明書の作成（CA証明書を使用して署名）
resource "tls_locally_signed_cert" "server" {
  cert_request_pem      = tls_cert_request.server.cert_request_pem # CSRのPEM形式データを指定
  ca_private_key_pem    = tls_private_key.root_ca.private_key_pem  # 署名するCAのプライベートキー
  ca_cert_pem           = tls_self_signed_cert.root_ca.cert_pem    # 署名するCAの証明書
  validity_period_hours = var.server.validity_period_hours
  # 発行された証明書に許可されているキー使用法のリスト
  allowed_uses = [
    "key_encipherment",  # この証明書の公開鍵は、他の鍵（主にセッション鍵）を暗号化するために使用できる
    "digital_signature", # この証明書の秘密鍵がデジタル署名の生成に使用できる
    "server_auth",       # この証明書がTLSウェブサーバー認証に使用できる
  ]
}

# ACMへの証明書インポート
resource "aws_acm_certificate" "main" {
  private_key       = tls_private_key.server.private_key_pem  # サーバ証明書の秘密鍵
  certificate_body  = tls_locally_signed_cert.server.cert_pem # サーバ証明書
  certificate_chain = tls_self_signed_cert.root_ca.cert_pem   # ルート証明書（CA証明書）
  lifecycle {
    create_before_destroy = true
  }
}

# 証明書ファイルのローカル保存
## ルート証明書（CA証明書）
resource "local_file" "root_ca_cert" {
  content  = tls_self_signed_cert.root_ca.cert_pem
  filename = "${path.module}/../../envs/${var.env}/certs/root_ca.pem"
}

## サーバー証明書（秘密鍵）
resource "local_file" "server_key" {
  content  = tls_private_key.server.private_key_pem
  filename = "${path.module}/../../envs/${var.env}/certs/server.key"
}

##　サーバー証明書
resource "local_file" "server_cert" {
  content  = tls_locally_signed_cert.server.cert_pem
  filename = "${path.module}/../../envs/${var.env}/certs/server.pem"
}
