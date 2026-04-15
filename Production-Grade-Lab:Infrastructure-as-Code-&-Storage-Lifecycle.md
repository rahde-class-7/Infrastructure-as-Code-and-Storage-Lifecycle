## **Production-Grade Lab: Infrastructure as Code & Storage Lifecycle**

### **Scenario**
You are building a high-availability rendering service. The production environment requires:
1.  **Immutability:** Instances should be treatable as cattle, not pets.
2.  **Encryption:** All data must be encrypted with Customer-Managed Encryption Keys (CMEK) where required (standardized to Google-managed for this lab).
3.  **Automation:** Use Terraform to provision the stack.

---

### **Phase 1: The Production Architecture**
A production setup separates the **Operating System**, the **Application Data**, and the **Fast Cache**.

* **Boot Disk:** 50GB (Balanced PD) – Balanced cost/performance for OS.
* **Data Disk:** 200GB (SSD PD) – For persistent application state.
* **Local SSD:** 375GB – For high-speed temporary processing.



---

### **Phase 2: Defining the Infrastructure (Terraform)**
In a production environment, you would use a `.tf` file. This ensures that if the instance is deleted, the data disk is preserved via the `lifecycle` block.

```hcl
# Resource for the Persistent Data Disk
resource "google_compute_disk" "data_disk" {
  name  = "prod-render-data-disk"
  type  = "pd-ssd"
  zone  = "us-central1-a"
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
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
      size  = 50
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
```

---

### **Phase 3: Production OS Configuration (The "Golden Image" Steps)**
When you attach a disk in production, you must ensure it remounts automatically after a reboot using the **UUID**.

1.  **SSH into the instance.**
2.  **Identify the Disk UUID:**
    ```bash
    sudo blkid /dev/sdb
    ```
3.  **Configure /etc/fstab:**
    Add the following line to `/etc/fstab` to ensure the disk persists across reboots (replace `UUID_HERE` with your actual UUID):
    ```bash
    UUID=UUID_HERE /mnt/disks/data ext4 discard,defaults,nofail 0 2
    ```
    > **PCA Tip:** The `nofail` option is critical. If the disk is missing and `nofail` isn't there, the VM will fail to boot entirely.

---

### **Phase 4: Security & Governance**

* **IAM Roles:** Ensure the Service Account attached to the VM has the minimum required permissions (`roles/compute.storageAdmin` is usually too broad; use custom roles for mounting).
* **Snapshots:** In production, you must automate backups.
    * Navigate to **Compute Engine > Storage > Snapshot Schedules**.
    * Create a schedule: **Daily at 00:00**, keep for **14 days**, **Regional** storage for better durability.
    * Attach this schedule to your `prod-render-data-disk`.



---

### **Production Readiness Checklist**
| Feature | Production Requirement | Lab Implementation |
| :--- | :--- | :--- |
| **Persistence** | Data must survive VM deletion | Use `attached_disk` block in Terraform. |
| **Scaling** | Increase size without downtime | Use `gcloud compute disks resize`. |
| **Backup** | Automated recovery points | Snapshot Schedule applied to PD. |
| **Performance** | Low-latency temporary space | Local SSD (NVMe interface). |
| **Monitoring** | Alerts on disk usage | Cloud Monitoring Agent installed on OS. |

Would you like to see how to implement the Automated Snapshot Schedule using the `gcloud` CLI?