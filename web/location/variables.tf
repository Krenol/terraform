variable "web_server_location" {
  type = string
}

variable "web_server_rg" {
  type = string
}

variable "resource_prefix" {
  type = string
}

variable "web_server_address_space" {
  type = string
}

variable "web_server_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "web_server_count" {
  type = number
}

variable "web_server_subnets" {
  type = map(any)
}

variable "terraform_script_version" {
  type = string
  validation {
    condition     = can(regex("^[0-9].[0-9].[0-9]$", var.terraform_script_version))
    error_message = "Invalid variable: terraform_script_version. Required format: x.x.x."
  }
}

variable "domain_name_label" {
  type = string
}
