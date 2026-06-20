module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  domain_name = trimsuffix(data.aws_route53_zone.mydomain.name, ".")
  zone_id     = data.aws_route53_zone.mydomain.zone_id

  subject_alternative_names = [
    "*.ocean-across.com",
  ]

  validation_method = "DNS"
  wait_for_validation = true 

  tags = local.common_tags
}


output "acm_certificate_arn" {
    description = "The ARN of the certificate"
    value = module.acm.acm_certificate_arn
}

output "acm_certificate_status" {
    description = "Status of the certifcate"
    value = module.acm.acm_certificate_status
}

output "distinct_domain_names" {
    description = "List of distinct domains names used for the validation."
    value = module.acm.distinct_domain_names
}