
#===========================================
#7. Create Producers VPC network

#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#7.1 Create VPC Network
#From Cloud Shell


/*
gcloud compute networks create vpc-demo-producer --project=$prodproject --subnet-mode=custom
*/

resource "google_compute_network" "vpc_demo_producer_network" {
  #name = "psc-ilb-network"
  name = "vpc-demo-producer-network"
  auto_create_subnetworks = false

  project = var.gcp_project_id_producer

}




#7.1.1 Create Subnet

#From Cloud Shell

/*
gcloud compute networks subnets create vpc-demo-us-west2 --project=$prodproject --range=10.0.2.0/24 --network=vpc-demo-producer --region=us-west2
*/

resource "google_compute_subnetwork" "vpc_demo_europe_west2_subnetwork" {
  name   = "vpc-demo-europe-west2-subnetwork"
  region = var.gcp_region

  project = var.gcp_project_id_producer

  network       = google_compute_network.vpc_demo_producer_network.id
  ip_cidr_range = "10.0.2.0/24"
}





#7.2 Create Cloud NAT instance
#Cloud NAT is not the same NAT used for PSC. Cloud NAT is used explicitly for internet access to download application packages.

#7.2.1 Create Cloud Router


resource "google_compute_router" "crnatprod_router" {
  name    = "crnatprod-router"
  region  = google_compute_subnetwork.vpc_demo_europe_west2_subnetwork.region
  network = google_compute_network.vpc_demo_producer_network.id

}

/*

#From Cloud Shell

gcloud compute routers create crnatprod --network vpc-demo-producer --region us-west2

*/

#7.2.2 Create Cloud NAT


/*

#From Cloud Shell

gcloud compute routers nats create cloudnatprod --router=crnatprod --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --enable-logging --region us-west2

*/

resource "google_compute_router_nat" "cloudnatprod_nat" {
  name                               = "cloudnatprod-nat"
  router                             = google_compute_router.crnatprod_router.name
  region                             = google_compute_router.crnatprod_router.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

#  log_config {
 #   enable = true
    #filter = "ERRORS_ONLY"
  #}
}



#===========================================
#8. Create compute instances

data "google_compute_image" "debian_image" {
  family  = "debian-10"
  project = "debian-cloud"
}


#From Cloud Shell
#8.1 Create instance www-01


resource "google_compute_instance" "www01_vm" {
  name         = "www-01"
  machine_type = "e2-medium"
  zone         = "${var.gcp_region}-b"
  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  network_interface {
    #network = "default"
    subnetwork = google_compute_subnetwork.vpc_demo_europe_west2_subnetwork.name      # "vpc-demo-europe-west2-subnetwork"
  }


  metadata_startup_script = file("${path.module}/startup.sh.tpl")
 

}



/*

 gcloud compute instances create www-01 \
    --zone=us-west2-a \
    --image-family=debian-9 \
    --image-project=debian-cloud \
    --subnet=vpc-demo-us-west2 --no-address \
    --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install tcpdump -y
apt-get install apache2 -y
a2ensite default-ssl
apt-get install iperf3 -y
a2enmod ssl
vm_hostname="$(curl -H "Metadata-Flavor:Google" \
http://169.254.169.254/computeMetadata/v1/instance/name)"
filter="{print \$NF}"
vm_zone="$(curl -H "Metadata-Flavor:Google" \
http://169.254.169.254/computeMetadata/v1/instance/zone \
| awk -F/ "${filter}")"
echo "Page on $vm_hostname in $vm_zone" | \
tee /var/www/html/index.html
systemctl restart apache2
iperf3 -s -p 5050'

*/

#From Cloud Shell
#8.2 Create instance www-02

resource "google_compute_instance" "www02_vm" {
  name         = "www-02"
  machine_type = "e2-medium"
  zone         = "${var.gcp_region}-b"
  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian_image.self_link
    }
  }

  network_interface {
    #network = "default"
    subnetwork = google_compute_subnetwork.vpc_demo_europe_west2_subnetwork.name # "vpc-demo-europe-west2-subnetwork"

    /* virtual machines with private IP only, omit to ensure that the instance is not accessible from the Internet.
      Do not include the access_config {} in the network interface block.

    access_config {
      // Ephemeral public IP
    }
    */

  }


  metadata_startup_script = file("${path.module}/startup.sh.tpl")
 

}



/*

gcloud compute instances create www-02 \
    --zone=us-west2-a \
    --image-family=debian-9 \
    --image-project=debian-cloud \
    --subnet=vpc-demo-us-west2 --no-address \
    --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install tcpdump -y
apt-get install apache2 -y
a2ensite default-ssl
apt-get install iperf3 -y
a2enmod ssl
vm_hostname="$(curl -H "Metadata-Flavor:Google" \
http://169.254.169.254/computeMetadata/v1/instance/name)"
filter="{print \$NF}"
vm_zone="$(curl -H "Metadata-Flavor:Google" \
http://169.254.169.254/computeMetadata/v1/instance/zone \
| awk -F/ "${filter}")"
echo "Page on $vm_hostname in $vm_zone" | \
tee /var/www/html/index.html
systemctl restart apache2
iperf3 -s -p 5050'

*/

#===========================================
#9. Create unmanaged instance group

#9.1 Create a unmanaged instance group consisting of www-01 & www-02

/*

#From Cloud Shell

gcloud compute instance-groups unmanaged create vpc-demo-ig-www --zone=europe-west2-b

#---------------------

gcloud compute instance-groups unmanaged add-instances vpc-demo-ig-www --zone=europe-west2-b --instances=www-01,www-02

#---------------------

*/

resource "google_compute_instance_group" "vpc-demo-ig-www" {
  name      = "vpc-demo-ig-www"
  zone      = "${var.gcp_region}-b"
  instances = [
    google_compute_instance.www01_vm.id,
    google_compute_instance.www02_vm.id,
    ]

  named_port {
    name = "http"
    port = "8080"
  }

  named_port {
    name = "https"
    port = "8443"
  }

  project = var.gcp_project_id_producer

#  lifecycle {
#    create_before_destroy = true
#  }
}




/*

gcloud compute health-checks create http hc-http-80 --port=80

*/

/*
resource "google_compute_https_health_check" "staging_health" {
  name         = "staging-health"
  request_path = "/health_check"
}
*/


resource "google_compute_health_check" "hc-http-80" {
  name = "hc-http-80"

  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "80"
  }
}




#================================================
#10. Create TCP backend services, forwarding rule & firewall
#
#10.1 Create the backend service

/*
resource "google_compute_backend_service" "staging_service" {
  name      = "staging-service"
  port_name = "https"
  protocol  = "HTTPS"

  backend {
    group = google_compute_instance_group.staging_group.id
  }

  health_checks = [
    google_compute_https_health_check.staging_health.id,
  ]
}
*/


resource "google_compute_region_backend_service" "vpc-demo-www-be-tcp" {
  #name   = "producer-service"
  name   = "vpc-demo-www-be-tcp"
  region = var.gcp_region

  load_balancing_scheme = "INTERNAL"
  protocol = "TCP"

  backend {
    group = google_compute_instance_group.vpc-demo-ig-www.id
    
  }

  health_checks = [google_compute_health_check.hc-http-80.id]
}

/*

gcloud compute backend-services create vpc-demo-www-be-tcp --load-balancing-scheme=internal --protocol=tcp --region=europe-west2 --health-checks=hc-http-80

gcloud compute backend-services add-backend vpc-demo-www-be-tcp --region=europe-west2 --instance-group=vpc-demo-ig-www --instance-group-zone=europe-west2-b

*/



#10.2 Create the forwarding rule
# Forwarding rule for Internal Load Balancing
resource "google_compute_forwarding_rule" "vpc_demo_www_ilb_tcp_target_service" {
  name   = "vpc-demo-www-ilb-tcp-target-serice"
  region = var.gcp_region
  
  ip_address = "10.0.2.10"
  ip_protocol = "TCP"
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.vpc-demo-www-be-tcp.id
  #port_range            = "80"
  all_ports             = true
  network               = google_compute_network.vpc_demo_producer_network.name
  subnetwork            = google_compute_subnetwork.vpc_demo_europe_west2_subnetwork.name
}


/*

gcloud compute forwarding-rules create vpc-demo-www-ilb-tcp --region=europe-west2 --load-balancing-scheme=internal --network=vpc-demo-producer --subnet=vpc-demo-eu-west2 --address=10.0.2.10 --ip-protocol=TCP --ports=all --backend-service=vpc-demo-www-be-tcp --backend-service-region=europe-west2

*/

#From Cloud Shell
#10.3 create a firewall rule to enable backend health checks

# allow all access from hleath check ranges

resource "google_compute_firewall" "vpc_demo_health_checks_fw" {
#  provider = google-beta
  name = "vpc-demo-health-checks-fw"
  network = google_compute_network.vpc_demo_producer_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
    ports = ["80", "443"]
  }
  direction = "INGRESS"

  # --enable-logging (argument not implemented )
}

/*

gcloud compute firewall-rules create vpc-demo-health-checks --allow tcp:80,tcp:443 --network vpc-demo-producer --source-ranges 130.211.0.0/22,35.191.0.0/16 --enable-logging

*/

#10.4. To allow IAP to connect to your VM instances, create a firewall rule that:

#Applies to all VM instances that you want to be accessible by using IAP.
#Allows ingress traffic from the IP range 35.235.240.0/20. This range contains all IP addresses that IAP uses for TCP forwarding.

#From Cloud Shell


# allow all access IP aadresses that IAP uses for TCP forwarding

resource "google_compute_firewall" "psclab-iap-prod_fw" {
#  provider = google-beta
  name = "psclab-iap-prod-fw"
  network = google_compute_network.vpc_demo_producer_network.id
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  direction = "INGRESS"

  # --enable-logging (argument not implemented )
}

/*

gcloud compute firewall-rules create psclab-iap-prod --network vpc-demo-producer --allow tcp:22 --source-ranges=35.235.240.0/20 --enable-logging

*/

#========================================
#11. Create TCP NAT subnet

/*

gcloud compute networks subnets create vpc-demo-us-west2-psc-tcp --network=vpc-demo-producer --region=us-west2 --range=192.168.0.0/24 --purpose=private-service-connect

*/

resource "google_compute_subnetwork" "vpc_demo_eu_west2_psc_tcp" {
  name   = "vpc-demo-eu-west2-psc-tcp"
  region = var.gcp_region

  #network       = google_compute_network.psc_ilb_network.id
  network       = google_compute_network.vpc_demo_producer_network.id
  purpose       =  "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = "192.168.0.0/24"
}



#==============================================================
#12. Create TCP service attachment and firewall rules

#12.1 Create the TCP service attachment

resource "google_compute_service_attachment" "vpc_demo_psc_west2_tcp_service_attachment" {
  name        = "vpc-demo-psc-west2-tcp-service-attachment"
  region      = var.gcp_region
  description = "A service attachment configured with Terraform"

  #domain_names             = ["gcp.tfacc.hashicorptest.com."]
  enable_proxy_protocol    = false
  connection_preference    = "ACCEPT_AUTOMATIC"
  nat_subnets              = [google_compute_subnetwork.vpc_demo_eu_west2_psc_tcp.id]
  target_service           = google_compute_forwarding_rule.vpc_demo_www_ilb_tcp_target_service.id
}

/*


gcloud compute service-attachments create vpc-demo-psc-west2-tcp --region=europe-west2 --producer-forwarding-rule=vpc-demo-www-ilb-tcp --connection-preference=ACCEPT_AUTOMATIC --nat-subnets=vpc-demo-eu-west2-psc-tcp



*/

#12.2. Validate the TCP service attachment

# not required

#gcloud compute service-attachments describe vpc-demo-psc-west2-tcp --region us-west2



#12.3 Create the firewall rule allowing TCP NAT subnet access to the ILB backend


# allow all access IP aadresses that IAP uses for TCP forwarding

resource "google_compute_firewall" "vpc_demo_allowpsc_tcp_fw" {
#  provider = google-beta
  project = var.gcp_project_id_producer

  name = "vpc-demo-allowpsc-tcp-fw"
  network = google_compute_network.vpc_demo_producer_network.id
  source_ranges = ["192.168.0.0/24"]
  allow {
    protocol = "all"
  }
  direction = "INGRESS"

  # --enable-logging (argument not implemented yet !!)
  # --priority (argument not implemented yet !!)
}

/*

gcloud compute --project=$prodproject firewall-rules create vpc-demo-allowpsc-tcp --direction=INGRESS --priority=1000 --network=vpc-demo-producer --action=ALLOW --rules=all --source-ranges=192.168.0.0/24 --enable-logging

*/




#**********************************************************************************





