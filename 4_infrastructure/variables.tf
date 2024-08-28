variable "region" {
  description = "AWS Region"
  default     = "eu-central-1"
}

variable "app_name" {
  description = "Application name"
  default     = "flask-app"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "192.168.0.0/24"
}