variable "service_api_token" {
  description = "Fake token used to prove custom Terraform default detection."
  type        = string
  default     = "tfPocToken0123456789abcdef9876543210"
  sensitive   = true
}
