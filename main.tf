terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file("F:/Terraform/GCP/terraform-318907-2bf23b02b681.json")

  project =  var.project
  region  = var.region
  zone    = var.zone
 
}
#----------------------------------------------------------------------------------
##Creating a New VPC 1 with custom subnetting
resource "google_compute_network" "vpc_network1" {
  name = "terraform-network1"
  auto_create_subnetworks = false
  
}

resource "time_sleep" "wait_30_seconds1" {
  depends_on = [google_compute_network.vpc_network1]
  create_duration = "30s"
}

#-----------------------------------------------------------------------------------
##Creating a New VPC 2 with custom subnetting
resource "google_compute_network" "vpc_network2" {
  depends_on = [time_sleep.wait_30_seconds1]
  name = "terraform-network2"
  auto_create_subnetworks = false
  
}

resource "time_sleep" "wait_30_seconds2" {
  depends_on = [google_compute_network.vpc_network2]
  create_duration = "30s"
}

#-----------------------------------------------------------------------------------
##Adding new subnet with 10.210.1.0/24 range into existing VCP 1 called "terraform-network1"
resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges1" {
  depends_on = [time_sleep.wait_30_seconds2]
  name          = "terraform-web"
  ip_cidr_range = "10.210.1.0/24"
  region        = "asia-south1"
  network       = "terraform-network1"
}

resource "time_sleep" "wait_30_seconds3" {
  depends_on = [google_compute_network.vpc_network2]
  create_duration = "30s"
}
#-----------------------------------------------------------------------------------
##Adding new subnet with 10.211.1.0/24 range into existing VCP 2 called "terraform-network2"
resource "google_compute_subnetwork" "network-with-private-secondary-ip-ranges2" {
  depends_on = [time_sleep.wait_30_seconds3]
  name          = "terraform-app"
  ip_cidr_range = "10.211.1.0/24"
  region        = "asia-south1"
  network       = "terraform-network2"
}

#-----------------------------------------------------------------------------------
# Creating Peering VPC1-VPC2
resource "google_compute_network_peering" "peering1" {
  name         = "peering1"
  network      = google_compute_network.vpc_network1.id
  peer_network = google_compute_network.vpc_network2.id
}

# Creating Peering VPC1-VPC2
resource "google_compute_network_peering" "peering2" {
  name         = "peering2"
  network      = google_compute_network.vpc_network2.id
  peer_network = google_compute_network.vpc_network1.id
}

#-----------------------------------------------------------------------------------
##Creating a Instance with out external IP and with custom subnet in VPC 1
resource "google_compute_instance" "vm_instance1" {
  name         = "terraform-instance1"
  machine_type = "f1-micro"
  zone    = "asia-south1-a"
  tags = ["web"]  #Network tags
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "terraform-network1"
    subnetwork = "terraform-web"
   
  }
}

#--------------------------------------------------------------------------------------------

##Creating a Instance with out external IP and with custom subnet in VPC 2
resource "google_compute_instance" "vm_instance2" {
  name         = "terraform-instance2"
  machine_type = "f1-micro"
  zone    = "asia-south1-a"
  tags = ["app"]  #Network tags
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "terraform-network2"
    subnetwork = "terraform-app"
    
  }
} 

#-----------------------------------------------------------------------------------
#Add Firewall for VPC 1
resource "google_compute_firewall" "gcpfirewall1" {
  name    = "web-firewall"
  network = "terraform-network1"
  source_ranges =["10.211.1.0/24"]
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

}

#-----------------------------------------------------------------------------------
#Add Firewall for VCP 2
resource "google_compute_firewall" "gcpfirewall2" {
  name    = "app-firewall"
  network = "terraform-network2"
   source_ranges =["10.210.1.0/24"]
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

}

#----------------------------------------------------------------------------------
# Adding IAP Access Rule to VPC 1

resource "google_compute_firewall" "gcpiapfw1" {
  name    = "allow-ssh-from-iap1"
  network = "terraform-network1"
   source_ranges =["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

}

#----------------------------------------------------------------------------------------
# Adding IAP Access Rule to VPC 1

resource "google_compute_firewall" "gcpiapfw2" {
  name    = "allow-ssh-from-iap2"
  network = "terraform-network2"
   source_ranges =["35.235.240.0/20"] 
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

}