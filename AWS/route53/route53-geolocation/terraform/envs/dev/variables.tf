variable "aws_region" {
  description = "AWS region for provider operations."
  type        = string
  default     = "us-east-1"
}

variable "root_domain" {
  description = "Root domain that already has a public hosted zone."
  type        = string
  default     = "hohihellohi.com"
}

variable "record_name" {
  description = "Traffic policy instance record FQDN."
  type        = string
  default     = "geo.hohihellohi.com"
}

variable "endpoint_ips" {
  description = "Endpoint IPv4 addresses for KR and default failover."
  type = object({
    kr                = string
    default_primary   = string
    default_secondary = string
  })
}

variable "ttl" {
  description = "TTL for traffic policy records."
  type        = number
  default     = 30
}

variable "health_check_type" {
  description = "Route53 health check type."
  type        = string
  default     = "HTTP"
}

variable "health_check_port" {
  description = "Route53 health check port."
  type        = number
  default     = 80
}

variable "health_check_resource_path" {
  description = "Route53 health check path."
  type        = string
  default     = "/"
}

variable "health_check_failure_threshold" {
  description = "Failure threshold for health checks."
  type        = number
  default     = 3
}

variable "health_check_request_interval" {
  description = "Health check request interval in seconds."
  type        = number
  default     = 30
}

variable "health_check_measure_latency" {
  description = "Whether to measure health check latency."
  type        = bool
  default     = false
}

variable "policy_name" {
  description = "Optional custom traffic policy name."
  type        = string
  default     = null
}

variable "policy_comment" {
  description = "Comment for traffic policy."
  type        = string
  default     = "Route53 geolocation + default failover for lab"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default = {
    Project = "route53-geolocation-failover-lab"
    Env     = "dev"
  }
}
