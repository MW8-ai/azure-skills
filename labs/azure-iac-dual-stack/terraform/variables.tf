variable "project_name" {
  description = "Short project identifier used in resource names."
  type        = string
  default     = "iaclab"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,12}$", var.project_name))
    error_message = "project_name must be 3-12 lowercase letters, numbers, or hyphens."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "Azure region for lab resources."
  type        = string
  default     = "eastus2"
}

variable "owner" {
  description = "Owner tag applied to resources."
  type        = string
  default     = "MW8-ai"
}
