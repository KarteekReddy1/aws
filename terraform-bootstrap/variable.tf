variable "env" {
  description = "Deployment environment (dev, stage, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "stage", "prod"], var.env)
    error_message = "env must be one of: dev, stage, prod"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default = "us-east-1"
}


