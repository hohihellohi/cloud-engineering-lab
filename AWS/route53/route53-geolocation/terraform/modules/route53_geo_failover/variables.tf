variable "root_domain" {
  description = "Root domain that already has a public Route 53 hosted zone."
  type        = string
  default     = "hohihellohi.com"

  validation {
    condition     = length(trimspace(var.root_domain)) > 0
    error_message = "root_domain must not be empty."
  }
}

variable "record_name" {
  description = "FQDN to create with traffic policy instance."
  type        = string
  default     = "geo.hohihellohi.com"

  validation {
    condition     = length(trimspace(var.record_name)) > 0
    error_message = "record_name must not be empty."
  }
}

variable "endpoint_ips" {
  description = "Endpoint IPv4 addresses for KR, default primary, and default secondary."
  type = object({
    kr                = string
    default_primary   = string
    default_secondary = string
  })

  validation {
    condition = alltrue([
      for ip in [var.endpoint_ips.kr, var.endpoint_ips.default_primary, var.endpoint_ips.default_secondary] : (
        can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", ip))
        && alltrue([for octet in split(".", ip) : tonumber(octet) >= 0 && tonumber(octet) <= 255])
        && !can(regex("^(0\\.|10\\.|127\\.|169\\.254\\.|192\\.168\\.|192\\.0\\.2\\.|198\\.51\\.100\\.|198\\.(1[89])\\.|203\\.0\\.113\\.)", ip))
        && !can(regex("^172\\.(1[6-9]|2[0-9]|3[0-1])\\.", ip))
        && !can(regex("^100\\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\\.", ip))
        && !can(regex("^(22[4-9]|23[0-9])\\.", ip))
      )
    ])
    error_message = "endpoint_ips must be public routable IPv4 addresses. Do not use private, loopback, link-local, multicast, or documentation ranges (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24)."
  }
}

variable "ttl" {
  description = "TTL for Route53 traffic policy instance records."
  type        = number
  default     = 30

  validation {
    condition     = var.ttl >= 1 && var.ttl <= 172800
    error_message = "ttl must be between 1 and 172800 seconds."
  }
}

variable "health_check_type" {
  description = "Route 53 health check type."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS", "HTTP_STR_MATCH", "HTTPS_STR_MATCH", "TCP"], var.health_check_type)
    error_message = "health_check_type must be one of HTTP, HTTPS, HTTP_STR_MATCH, HTTPS_STR_MATCH, TCP."
  }
}

variable "health_check_port" {
  description = "Port used by Route 53 health checks."
  type        = number
  default     = 80

  validation {
    condition     = var.health_check_port >= 1 && var.health_check_port <= 65535
    error_message = "health_check_port must be between 1 and 65535."
  }
}

variable "health_check_resource_path" {
  description = "Resource path for HTTP/HTTPS health checks."
  type        = string
  default     = "/"
}

variable "health_check_failure_threshold" {
  description = "Consecutive health check failures before endpoint is unhealthy."
  type        = number
  default     = 3

  validation {
    condition     = var.health_check_failure_threshold >= 1 && var.health_check_failure_threshold <= 10
    error_message = "health_check_failure_threshold must be between 1 and 10."
  }
}

variable "health_check_request_interval" {
  description = "Route 53 health check interval in seconds."
  type        = number
  default     = 30

  validation {
    condition     = contains([10, 30], var.health_check_request_interval)
    error_message = "health_check_request_interval must be 10 or 30."
  }
}

variable "health_check_measure_latency" {
  description = "Whether to measure latency for health checks."
  type        = bool
  default     = false
}

variable "policy_name" {
  description = "Optional custom Route53 traffic policy name."
  type        = string
  default     = null
}

variable "policy_comment" {
  description = "Comment for the Route53 traffic policy."
  type        = string
  default     = "KR geolocation + default failover policy"
}

variable "tags" {
  description = "Common tags for health checks."
  type        = map(string)
  default     = {}
}
