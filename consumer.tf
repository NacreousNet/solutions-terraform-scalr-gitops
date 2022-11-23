

/*


#===========================================
#13. Create Consumers VPC network

#13.1 VPC Network 

gcloud compute networks create vpc-demo-consumer --project=$consumerproject --subnet-mode=custom



#13.1.1 Create Subnet for PSC



#13.1.2 Create a static IP address for TCP applications

#From Cloud Shell


gcloud compute addresses create vpc-consumer-psc-tcp --region=us-west2 --subnet=consumer-subnet --addresses 10.0.60.100


resource "google_compute_address" "psc_ilb_consumer_address" {
  name   = "psc-ilb-consumer-address"
  region = var.gcp_region

  subnetwork   = "default"
  address_type = "INTERNAL"
}


#13.1.3 Create Firewall Rules

/*

To allow IAP to connect to your VM instances, create a firewall rule that:

Applies to all VM instances that you want to be accessible by using IAP.
Allows ingress traffic from the IP range 35.235.240.0/20. This range contains all IP addresses that IAP uses for TCP forwarding.
From Cloud Shell

*/

/*
gcloud compute firewall-rules create psclab-iap-consumer --network vpc-demo-consumer --allow tcp:22 --source-ranges=35.235.240.0/20 --enable-logging


#13.1.4 Although not required for PSC create a egress firewall rule to monitor consumer PSC traffic to the producers service attachment


gcloud compute --project=$consumerproject firewall-rules create vpc-consumer-psc --direction=EGRESS --priority=1000 --network=vpc-demo-consumer --action=ALLOW --rules=all --destination-ranges=10.0.60.0/24 --enable-logging


#13.2 Create Cloud NAT instance

#Cloud NAT is not the same NAT used for PSC. Cloud NAT is used explicitly for internet access to download application packages

#13.2.1 Create Cloud Router

#From Cloud Shell


gcloud compute routers create crnatconsumer --network vpc-demo-consumer --region us-west2

#13.2.2 Create Cloud NAT

#From Cloud Shell

gcloud compute routers nats create cloudnatconsumer --router=crnatconsumer --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --enable-logging --region us-west2


#=================================================================
#14. Create test instance VM

#From Cloud Shell

/*

gcloud compute instances create test-instance-1 \
    --zone=us-west2-a \
    --image-family=debian-9 \
    --image-project=debian-cloud \
    --subnet=consumer-subnet --no-address \
    --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install iperf3 -y
apt-get install tcpdump -y'

*/


#=================================================================
#15. Create TCP service attachment

#From Cloud Shell

/*
# create forwarding rule to Service Producer - Service Attachment

gcloud compute forwarding-rules create vpc-consumer-psc-fr-tcp --region=us-west2 --network=vpc-demo-consumer --address=vpc-consumer-psc-tcp --target-service-attachment=projects/$prodproject/regions/us-west2/serviceAttachments/vpc-demo-psc-west2-tcp


resource "google_compute_forwarding_rule" "vpc_consumer_psc_fr_tcp" {
  name   = "vpc-consumer-psc-fr-tcp-forwarding-rule"
  region = var.gcp_region

  target                = google_compute_service_attachment.vpc_demo_psc_west2_tcp_service_attachment.id
  load_balancing_scheme = "" # need to override EXTERNAL default when target is a service attachment
  network               = "default"
  ip_address            = google_compute_address.psc_ilb_consumer_address.id
}


#===========================================





#-----------------------------------------------------------------------------------------


#******* TO DO




*/