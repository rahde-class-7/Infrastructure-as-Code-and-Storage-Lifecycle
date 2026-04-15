#The GCS backend bucket must be created first, 
#before terraform init, because Terraform cannot use a backend that does not already exist.

# https://www.terraform.io/language/settings/backends/gcs
terraform {
  backend "gcs" {
    bucket = "terraform-backend-bucket-01"
    prefix = "terraform/state"
  }
}
