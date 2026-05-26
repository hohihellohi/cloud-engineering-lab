output "record_fqdn" {
  description = "Policy instance record name."
  value       = module.route53_geo_failover.record_fqdn
}

output "traffic_policy_id" {
  description = "Route53 traffic policy ID."
  value       = module.route53_geo_failover.traffic_policy_id
}

output "traffic_policy_version" {
  description = "Route53 traffic policy version."
  value       = module.route53_geo_failover.traffic_policy_version
}

output "health_check_ids" {
  description = "Health checks mapped by endpoint key."
  value       = module.route53_geo_failover.health_check_ids
}
