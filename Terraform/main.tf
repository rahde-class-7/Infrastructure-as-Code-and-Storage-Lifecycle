  # Resource for the Persistent Data Disk
resource "google_compute_disk" "data_disk" {
  name  = "prod-render-data-disk"
  type  = "pd-ssd"
  zone  = "us-east4-a"
  size  = 200
  labels = {
    environment = "production"
    team        = "rendering"
  }
}

# Resource for the VM Instance
resource "google_compute_instance" "prod_vm" {
  name         = "prod-render-vm-01"
  machine_type = "n2-standard-4"
  zone         = "us-east4-a"

  boot_disk {
    initialize_params {
      image = "centos-stream-10-arm64-v20260413"
      size  = 500
      type  = "pd-balanced"
    }
  }

  # Attaching the independent data disk
  attached_disk {
    source      = google_compute_disk.data_disk.id
    device_name = "data-storage"
  }

  # Scratch space for high IOPS
  scratch_disk {
    interface = "NVME"
  }

  network_interface {
    network = "default"
    # In production, use private IPs and Cloud NAT
  }
}