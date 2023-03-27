terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.58.0"
    }
  }
}

provider "google" {
  region = "europe-west1"
  project = var.project_id
  credentials = var.credentials
}

variable "project_id" {
  type        = string
  sensitive   = true
}

variable "credentials" {
  type        = string
  sensitive   = true
}

variable "cluster_name" {}

resource "google_container_cluster" "gke_cluster" {
  name               = var.cluster_name
  location           = "europe-west1"
  initial_node_count = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    machine_type = "n1-standard-1"

    disk_size_gb = 20

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
}

resource "google_container_node_pool" "gke_node_pool" {
  name       = "gke-node-pool"
  location   = "europe-west1"
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 2

  node_config {
    machine_type = "n1-standard-1"

    disk_size_gb = 20

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_compute_firewall" "gke_cluster_firewall" {
  name    = "gke-cluster-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = [var.cluster_name]
}

output "gke_cluster_endpoint" {
  value = google_container_cluster.gke_cluster.endpoint
}

output "gke_cluster_ca_certificate" {
  value = google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
}