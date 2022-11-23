#23. Cleanup steps

#Producer network clean up steps

#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#From a single cloud shell in the Producer project terminal delete lab components


gcloud compute routers nats delete cloudnatprod --router=crnatprod --region=europe-west2 --quiet

gcloud compute routers delete crnatprod --region=europe-west2 --quiet

gcloud compute instances delete www-01 --zone=europe-west2-b --quiet

gcloud compute instances delete www-02 --zone=europe-west2-b --quiet

gcloud compute service-attachments delete vpc-demo-psc-west2-tcp --region=europe-west2 --quiet

gcloud compute forwarding-rules delete vpc-demo-www-ilb-tcp --region=europe-west2 --quiet

gcloud compute backend-services delete vpc-demo-www-be-tcp --region=europe-west2 --quiet

gcloud compute instance-groups unmanaged delete vpc-demo-ig-www --zone=europe-west2-b --quiet

gcloud compute health-checks delete hc-http-80 --quiet

gcloud compute firewall-rules delete vpc-demo-allowpsc-tcp --quiet

gcloud compute firewall-rules delete vpc-demo-health-checks --quiet

gcloud compute firewall-rules delete psclab-iap-prod --quiet

gcloud compute networks subnets delete vpc-demo-eu-west2 --region=europe-west2 --quiet

gcloud compute networks subnets delete vpc-demo-eu-west2-psc-tcp --region=europe-west2 --quiet

gcloud compute networks delete vpc-demo-producer --quiet
#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#Consumer network clean up steps

#From a single cloud shell in the Producer project terminal delete lab components


gcloud compute routers nats delete cloudnatconsumer --router=crnatconsumer --region=europe-west2 --quiet

gcloud compute routers delete crnatconsumer --region=europe-west2 --quiet

gcloud compute instances delete test-instance-1 --zone=europe-west2-b --quiet

gcloud compute forwarding-rules delete vpc-consumer-psc-fr-tcp --region=europe-west2 --quiet

gcloud compute addresses delete vpc-consumer-psc-tcp --region=europe-west2 --quiet

gcloud compute firewall-rules delete psclab-iap-consumer --quiet

gcloud compute networks subnets delete consumer-subnet --region=europe-west2 --quiet

gcloud compute firewall-rules delete vpc-consumer-psc --quiet

gcloud compute networks delete vpc-demo-consumer --quiet

