variable "subscription_id" {
  type = string
}
variable "image_version" {
  type = string
}
variable "instance_count" {
  type    = number
  default = 1
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}
variable "vmss_sku" {
  type    = string
  default = "Standard_B1s"
}
