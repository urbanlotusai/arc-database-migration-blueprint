variable "name" {
  type = string
}

variable "server_side_encryption_config_data" {
  type = any
}

variable "public_access_config" {
  type = any
}

variable "tags" {
  type = map(string)
}
