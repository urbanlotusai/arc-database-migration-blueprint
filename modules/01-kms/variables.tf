variable "alias" {
  type = string
}

variable "policy" {
  type = string
}

variable "description" {
  type = string
}

variable "deletion_window_in_days" {
  type = number
}

variable "tags" {
  type = map(string)
}
