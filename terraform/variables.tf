variable "app_name" {
  description = "The name of the app"
}

variable "app_domain" {
  description = "The domain where the app is hosted"
}

variable "aws_region" {
  default     = "eu-west-3"
  description = "The region on which to deploy the AWS resources"
}

## Values retrieved from the Fly app

variable "app_cname_name" {
  description = "The name of the CNAME record to add to Route 53 DNS"
}

variable "app_cname_record" {
  description = "The CNAME record to add to Route 53 DNS"
}

variable "app_a_record" {
  description = "The A record to add to Route 53 DNS"
}

variable "app_aaaa_record" {
  description = "The AAAA record to add to Route 53 DNS"
}
