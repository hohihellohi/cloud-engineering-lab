locals {
  normalized_root_domain = trimsuffix(var.root_domain, ".")
  normalized_record_name = trimsuffix(var.record_name, ".")
  effective_policy_name  = coalesce(var.policy_name, "geo-default-failover-${replace(trimsuffix(var.record_name, "."), ".", "-")}")

  endpoint_ips = {
    kr                = var.endpoint_ips.kr
    default_primary   = var.endpoint_ips.default_primary
    default_secondary = var.endpoint_ips.default_secondary
  }
}

data "aws_route53_zone" "selected" {
  name         = "${local.normalized_root_domain}."
  private_zone = false
}

resource "aws_route53_health_check" "endpoint" {
  for_each = local.endpoint_ips

  type              = var.health_check_type
  ip_address        = each.value
  port              = var.health_check_port
  resource_path     = var.health_check_resource_path
  failure_threshold = var.health_check_failure_threshold
  request_interval  = var.health_check_request_interval
  measure_latency   = var.health_check_measure_latency

  tags = merge(
    var.tags,
    {
      Name = "${local.effective_policy_name}-${each.key}-hc"
    }
  )
}

resource "aws_route53_traffic_policy" "this" {
  name    = local.effective_policy_name
  comment = var.policy_comment

  document = jsonencode({
    AWSPolicyFormatVersion = "2015-10-01"
    RecordType             = "A"
    StartRule              = "geo_rule"
    Endpoints = {
      kr_endpoint = {
        Type  = "value"
        Value = var.endpoint_ips.kr
      }
      default_primary_endpoint = {
        Type  = "value"
        Value = var.endpoint_ips.default_primary
      }
      default_secondary_endpoint = {
        Type  = "value"
        Value = var.endpoint_ips.default_secondary
      }
    }
    Rules = {
      geo_rule = {
        RuleType = "geo"
        Locations = [
          {
            EndpointReference = "kr_endpoint"
            Country           = "KR"
            IsDefault         = false
            HealthCheck       = aws_route53_health_check.endpoint["kr"].id
          },
          {
            RuleReference = "default_failover_rule"
            Country       = "*"
          }
        ]
      }
      default_failover_rule = {
        RuleType = "failover"
        Primary = {
          EndpointReference = "default_primary_endpoint"
          HealthCheck       = aws_route53_health_check.endpoint["default_primary"].id
        }
        Secondary = {
          EndpointReference = "default_secondary_endpoint"
          HealthCheck       = aws_route53_health_check.endpoint["default_secondary"].id
        }
      }
    }
  })
}

resource "aws_route53_traffic_policy_instance" "this" {
  name                   = local.normalized_record_name
  hosted_zone_id         = data.aws_route53_zone.selected.zone_id
  traffic_policy_id      = aws_route53_traffic_policy.this.id
  traffic_policy_version = aws_route53_traffic_policy.this.version
  ttl                    = var.ttl
}
