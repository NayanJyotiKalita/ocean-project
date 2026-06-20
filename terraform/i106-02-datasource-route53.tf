data "aws_route53_zone" "mydomain" {
  name         = "ocean-across.com"    # just for demo
}

output "mydamain_zone_id" {
  description = "The Host Zone ID of our Hosted Zone"
  value = data.aws_route53_zone.mydomain.zone_id
}

output "mydomain_name" {
  description = "The Hosted Zone name of our Hosted Zone"
  value = data.aws_route53_zone.mydomain.name
}

output "mydomain_name_servers" {
  description = "The name servers in our Hosted Zone"
  value = data.aws_route53_zone.mydomain.name_servers
}

