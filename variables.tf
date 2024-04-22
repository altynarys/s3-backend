variable "profile_name" {
  description = "AWS CLI profile name"
  type        = string
  default     = "acc_3_admin"
}

variable "main_region" {
  description = "Main region"
  type        = string
  default     = "us-east-1"
}

variable "base_name" {
  description = "Base name for all resources"
  type        = string
  default     = "bsd-uchicago-312"
}

variable "main_tags" {
  description = "Tags to apply to resources created"
  type        = map(string)
  default = {
    TechnicalContact = "DevOps"
    Environment = "dev"
    ControlledBy = "terraform"
  }
}

variable "newer_noncurrent_versions" {
  description = "The number of noncurrent versions Amazon S3 will retain"
  type        = number
  default     = 5
}

variable "noncurrent_days" {
  description = "The number of days Amazon S3 will retain noncurrent versions"
  type        = number
  default     = 7
}
