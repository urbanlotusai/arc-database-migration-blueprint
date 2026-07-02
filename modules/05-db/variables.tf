variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "environment" {
  type = string
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "port" {
  type = number
}

variable "username" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_group_data" {
  type = any
}

variable "kms_key_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "backup_retention_period" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

variable "tags" {
  type = map(string)
}
