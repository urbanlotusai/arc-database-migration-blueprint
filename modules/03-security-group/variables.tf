variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ingress_rules" {
  type = any
}

variable "egress_rules" {
  type = any
}

variable "tags" {
  type = map(string)
}
