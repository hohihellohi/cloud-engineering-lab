output "zone_id" {
  description = "Route53 hosted zone ID used for policy instance."
  value       = data.aws_route53_zone.selected.zone_id
}

output "record_fqdn" {
  description = "Traffic policy instance record name."
  value       = aws_route53_traffic_policy_instance.this.name
}

output "traffic_policy_id" {
  description = "Route53 traffic policy ID."
  value       = aws_route53_traffic_policy.this.id
}

output "traffic_policy_version" {
  description = "Route53 traffic policy version."
  value       = aws_route53_traffic_policy.this.version
}

output "health_check_ids" {
  description = "Route53 health check IDs by endpoint key."
  value       = { for k, v in aws_route53_health_check.endpoint : k => v.id }
}
