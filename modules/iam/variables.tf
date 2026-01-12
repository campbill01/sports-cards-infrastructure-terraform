variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "iam_path" {
  description = "Path for IAM resources"
  type        = string
  default     = "/"
}

variable "iam_users" {
  description = "Map of IAM users to create"
  type = map(object({
    policies = list(string)
  }))
  default = {}
}

variable "iam_groups" {
  description = "Map of IAM groups to create"
  type = map(object({
    policies = list(string)
    members  = list(string)
  }))
  default = {}
}

variable "iam_roles" {
  description = "Map of IAM roles to create"
  type = map(object({
    assume_role_policy = string
    policies           = list(string)
  }))
  default = {}
}

variable "custom_policies" {
  description = "Map of custom IAM policies to create"
  type = map(object({
    description = string
    policy_json = string
  }))
  default = {}
}

variable "service_linked_roles" {
  description = "Map of service-linked roles to create"
  type        = map(string)
  default     = {}
}

variable "create_access_keys" {
  description = "Set of users to create access keys for (stored in SSM)"
  type        = set(string)
  default     = []
}

variable "oidc_providers" {
  description = "Map of OIDC providers for federated access"
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
