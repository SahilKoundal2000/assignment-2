provider "google" {
  project = "dc-assi"
  region  = "us-central1"
}

resource "google_compute_network" "vpc_network" {
  name = "limbad-flask-vpc"  # Added prefix
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "limbad-public-subnet"  # Added prefix
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "limbad-private-subnet"  # Added prefix
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-central1"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_instance" "flask_instance" {
  name         = "limbad-flask-app-instance"  # Added prefix
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {}
  }

  metadata = {
    gce-container-declaration = <<EOF
    spec:
      containers:
        - name: flask-app
          image: gcr.io/dc-assi/mihir-flask:latest
          ports:
            - containerPort: 5000
    EOF
  }

  tags = ["limbad-flask-app"]  # Added prefix
}

resource "google_compute_firewall" "flask_firewall" {
  name    = "limbad-flask-firewall"  # Added prefix
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["5000"]
  }

  source_ranges = ["0.0.0.0/0"]
}
