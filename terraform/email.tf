resource "aws_ses_domain_identity" "email" {
  domain = var.app_domain
}

resource "aws_ses_configuration_set" "default" {
  name = "default_configuration_set"

  delivery_options {
    tls_policy = "Require"
  }
}

# TODO assign default configuration set

resource "aws_ses_domain_dkim" "email" {
  domain = aws_ses_domain_identity.email.domain
}

resource "aws_route53_record" "email_dkim_record" {
  count   = 3
  zone_id = aws_route53_zone.primary.zone_id
  name    = "${element(aws_ses_domain_dkim.email.dkim_tokens, count.index)}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.email.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

resource "aws_ses_domain_identity_verification" "email_verification" {
  domain = aws_ses_domain_identity.email.id

  depends_on = [aws_route53_record.email_dkim_record]
}

resource "aws_iam_user" "ses" {
  name = "${var.app_name}-ses"
}

resource "aws_iam_access_key" "ses" {
  user = aws_iam_user.ses.name
}

resource "aws_iam_user_policy" "ses_rw" {
  name = "${var.app_name}_send_raw_email"
  user = aws_iam_user.ses.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}
