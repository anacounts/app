resource "aws_route53_zone" "primary" {
  name = var.app_domain

  tags = {
    Name = var.app_domain
  }
}

resource "aws_route53_record" "app_cname" {
  zone_id = aws_route53_zone.primary.id
  name    = var.app_cname_name
  type    = "CNAME"
  ttl     = 300
  records = [var.app_cname_record]
}

resource "aws_route53_record" "app_a" {
  zone_id = aws_route53_zone.primary.id
  name    = "app"
  type    = "A"
  ttl     = 300
  records = [var.app_a_record]
}

resource "aws_route53_record" "app_aaaa" {
  zone_id = aws_route53_zone.primary.id
  name    = "app"
  type    = "AAAA"
  ttl     = 300
  records = [var.app_aaaa_record]
}
