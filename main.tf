provider "google" {
    project = "orbital-outpost-442521-r6"
    region = "northamerica-northeast-2"
}

# VPC
resource "google_compute_network" "sahil_vpc" {
  name                    = "sahil-vpc"
  auto_create_subnetworks = false
}

# Public Subnet
resource "google_compute_subnetwork" "sahil_public_subnet" {
  name          = "sahil-public-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "northamerica-northeast2"
  network       = google_compute_network.sahil_vpc.id
}

# Private Subnet
resource "google_compute_subnetwork" "sahil_private_subnet" {
  name          = "sahil-private-subnet"
  ip_cidr_range = "10.0.2.0/24"
  region        = "northamerica-northeast2"
  network       = google_compute_network.sahil_vpc.id
}

# Firewall rule to allow access to the application port 5000
resource "google_compute_firewall" "sahil_app_firewall" {
  name    = "sahil-app-firewall"
  network = google_compute_network.sahil_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["sahil-app"]
}

# Firewall rule to allow SSH access
resource "google_compute_firewall" "sahil_ssh_firewall" {
  name    = "sahil-ssh-firewall"
  network = google_compute_network.sahil_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["sahil-app"]
}

# Compute Engine Instance
resource "google_compute_instance" "sahil_instance" {
  name         = "sahil-instance"
  machine_type = "e2-medium"
  zone         = "northamerica-northeast2-a"
  tags         = ["sahil-app"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    network    = google_compute_network.sahil_vpc.id
    subnetwork = google_compute_subnetwork.sahil_public_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    gce-container-declaration = <<EOF
spec:
  containers:
    - image: 'sahilkoundal2023/python-backend:latest'
      name: sahil-flask-app
      ports:
        - containerPort: 5000
      restartPolicy: Always
EOF
  }

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
