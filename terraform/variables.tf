variable "resource_group_name" {
  description = "The name for the Azure Resource Group."
  type        = string
  default     = "better-llm-demo-rg"
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "East US"
}

variable "cluster_name" {
  description = "The name for the AKS cluster."
  type        = string
  default     = "better-llm-aks-cluster"
}

variable "dns_prefix" {
  description = "The DNS prefix for the AKS cluster's API server."
  type        = string
  default     = "better-llm-akscluster-api"
}

variable "budget_email" {
  description = "Email address for budget alerts"
  type        = string
  default     = "sobhan.21.samantaray@gmail.com"
}