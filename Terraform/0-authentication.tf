terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0" 
    }
  }
}

provider "google" {
  project = "class-seven-point"
  region  = "us-east4"
}


resource "null_resource" "check_ansible" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "ansible --version"
  }
}