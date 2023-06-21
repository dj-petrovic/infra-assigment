packer {
  required_plugins {
    azure-arm = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/azure"
    }
  }
}

variable "client_id" {
  type    = string
  default = ""
}

variable "client_secret" {
  type    = string
  default = ""
}

variable "subscription_id" {
  type    = string
  default = ""
}

variable "tenant_id" {
  type    = string
  default = ""
}
variable "image_version" {
  type    = string
  default = "1.0.0"
}


source "azure-arm" "ubuntu" {
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"

  managed_image_name                = "nginx-image-${var.image_version}"
  managed_image_resource_group_name = "packer-images"

  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "UbuntuServer"
  image_sku       = "18.04-LTS"

  location = "East US"
  vm_size  = "Standard_B1s"
}

build {
  sources = ["source.azure-arm.ubuntu"]

  provisioner "shell-local" {
    inline = ["echo Updating Packages"]
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get upgrade -y",
      "sudo apt-get update",
    ]
  }
  provisioner "shell-local" {
    inline = ["echo Install Nginx"]
  }
  provisioner "shell" {
    inline = ["sudo apt-get install -y nginx"]
  }

  provisioner "shell-local" {
    inline = ["echo Check Nginx service is running"]
  }

  provisioner "shell" {
    inline = ["sudo systemctl status nginx"]
  }
  provisioner "shell-local" {
    inline = ["echo Configuring Nginx"]
  }
  provisioner "shell" {
    inline = [
      "echo Hello World from $(hostname) - PAGE 1 DISPLAYING | sudo tee /var/www/html/page1.html",
      "echo Hello World from $(hostname) - PAGE 2 DISPLAYING | sudo tee /var/www/html/page2.html",
    ]
  }

  post-processor "manifest" {
    output = "nginx-manifest.json"
  }
}