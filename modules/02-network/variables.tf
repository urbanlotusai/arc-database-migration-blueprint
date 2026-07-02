variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "environment" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "tags" {
  type = map(string)
}
