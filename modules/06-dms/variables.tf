variable "prefix" {
  type = string
}

variable "instance_id" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "instance_engine_version" {
  type = string
}

variable "instance_multi_az" {
  type = bool
}

variable "instance_kms_key_arn" {
  type = string
}

variable "subnet_group_id" {
  type = string
}

variable "subnet_group_subnet_ids" {
  type = list(string)
}

variable "instance_vpc_security_group_ids" {
  type = list(string)
}

variable "endpoints" {
  type = any
}

variable "replication_tasks" {
  type = any
}

variable "tags" {
  type = map(string)
}
