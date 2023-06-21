variable "sku" {
  type = object({
    name     = string
    tier     = string
    capacity = number
  })
  default = {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }
}
