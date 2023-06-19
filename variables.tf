variable "application_name" {
  description = "Name of the application"
  type        = string
}

variable "sns_endpoint" {
  description = "Terraform version to install in CodeBuild Container"
  type        = string
}

variable "github_repository_id" {
  description = "ID of the main github_repo"
  type        = string
}

variable "codestar_connection_arn" {
  description = "Codestar Connection Arn"
  type        = string
}
