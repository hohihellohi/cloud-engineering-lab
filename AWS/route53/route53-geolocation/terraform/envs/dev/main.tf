provider "aws" {
  region = var.aws_region
}

module "route53_geo_failover" {
  source = "../../modules/route53_geo_failover"

  root_domain                    = var.root_domain
  record_name                    = var.record_name
  endpoint_ips                   = var.endpoint_ips
  ttl                            = var.ttl
  health_check_type              = var.health_check_type
  health_check_port              = var.health_check_port
  health_check_resource_path     = var.health_check_resource_path
  health_check_failure_threshold = var.health_check_failure_threshold
  health_check_request_interval  = var.health_check_request_interval
  health_check_measure_latency   = var.health_check_measure_latency
  policy_name                    = var.policy_name
  policy_comment                 = var.policy_comment
  tags                           = var.tags
}
