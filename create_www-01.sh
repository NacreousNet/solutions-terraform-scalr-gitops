gcloud compute instances create www-01 \
    --zone=europe-west2-b \
    --image-family=debian-10 \
    --image-project=debian-cloud \
    --subnet=vpc-demo-eu-west2 --no-address \
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

gcloud compute instances create www-02 \
    --zone=europe-west2-b \
    --image-family=debian-10 \
    --image-project=debian-cloud \
    --subnet=vpc-demo-eu-west2 --no-address \
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

#==============================================================
#7. Create Producers VPC network

#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#VPC Network
#From Cloud Shell


gcloud compute networks create vpc-demo-producer --project=$prodproject --subnet-mode=custom
#Create Subnet

#From Cloud Shell


gcloud compute networks subnets create vpc-demo-us-west2 --project=$prodproject --range=10.0.2.0/24 --network=vpc-demo-producer --region=us-west2
#Create Cloud NAT instance
#Cloud NAT is not the same NAT used for PSC. Cloud NAT is used explicitly for internet access to download application packages.

#Create Cloud Router

#From Cloud Shell


gcloud compute routers create crnatprod --network vpc-demo-producer --region us-west2
#Create Cloud NAT

#From Cloud Shell


gcloud compute routers nats create cloudnatprod --router=crnatprod --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --enable-logging --region us-west2


#8. Create compute instances

#From Cloud Shell create instance www-01


/* gcloud compute instances create www-01 \
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

#From Cloud Shell create instance www-02


/* gcloud compute instances create www-02 \
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

#9. Create unmanaged instance group

#Create a unmanaged instance group consisting of www-01 & www-02

#From Cloud Shell


gcloud compute instance-groups unmanaged create vpc-demo-ig-www --zone=europe-west2-b

gcloud compute instance-groups unmanaged add-instances vpc-demo-ig-www --zone=europe-west2-b --instances=www-01,www-02

gcloud compute health-checks create http hc-http-80 --port=80

#================================================
#10. Create TCP backend services, forwarding rule & firewall

#From Cloud Shell create the backend service


gcloud compute backend-services create vpc-demo-www-be-tcp --load-balancing-scheme=internal --protocol=tcp --region=europe-west2 --health-checks=hc-http-80

gcloud compute backend-services add-backend vpc-demo-www-be-tcp --region=europe-west2 --instance-group=vpc-demo-ig-www --instance-group-zone=europe-west2-b

#From Cloud Shell create the forwarding rule


gcloud compute forwarding-rules create vpc-demo-www-ilb-tcp --region=europe-west2 --load-balancing-scheme=internal --network=vpc-demo-producer --subnet=vpc-demo-eu-west2 --address=10.0.2.10 --ip-protocol=TCP --ports=all --backend-service=vpc-demo-www-be-tcp --backend-service-region=europe-west2

#From Cloud Shell create a firewall rule to enable backend health checks


gcloud compute firewall-rules create vpc-demo-health-checks --allow tcp:80,tcp:443 --network vpc-demo-producer --source-ranges 130.211.0.0/22,35.191.0.0/16 --enable-logging

#To allow IAP to connect to your VM instances, create a firewall rule that:

#Applies to all VM instances that you want to be accessible by using IAP.
#Allows ingress traffic from the IP range 35.235.240.0/20. This range contains all IP addresses that IAP uses for TCP forwarding.
#From Cloud Shell


gcloud compute firewall-rules create psclab-iap-prod --network vpc-demo-producer --allow tcp:22 --source-ranges=35.235.240.0/20 --enable-logging


#========================================
#11. Create TCP NAT subnet

#From Cloud Shell


gcloud compute networks subnets create vpc-demo-eu-west2-psc-tcp --network=vpc-demo-producer --region=europe-west2 --range=192.168.0.0/24 --purpose=private-service-connect


#=======================================
#12. Create TCP service attachment and firewall rules

#From Cloud Shell create the TCP service attachment


gcloud compute service-attachments create vpc-demo-psc-west2-tcp --region=europe-west2 --producer-forwarding-rule=vpc-demo-www-ilb-tcp --connection-preference=ACCEPT_AUTOMATIC --nat-subnets=vpc-demo-eu-west2-psc-tcp

#Validate the TCP service attachment


gcloud compute service-attachments describe vpc-demo-psc-west2-tcp --region europe-west2

#From Cloud Shell create the firewall rule allowing TCP NAT subnet access to the ILB backend


gcloud compute --project=$prodproject firewall-rules create vpc-demo-allowpsc-tcp --direction=INGRESS --priority=1000 --network=vpc-demo-producer --action=ALLOW --rules=all --source-ranges=192.168.0.0/24 --enable-logging


#===========================================
#13. Create Consumers VPC network

#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#In the following section the consumer VPC is configured in a separate project. Communication between the consumer and producer network is accomplished through the service attachment defined in the consumers network.

#VPC Network
#Codelab requires two projects, although not a requirement for PSC. Note the references to support single or multiple projects.

#Single Project - Update project to support producer and consumer network

#Inside Cloud Shell, make sure that your project id is set up


gcloud config list project
gcloud config set project [YOUR-PROJECT-NAME]
consumerproject=YOUR-PROJECT-NAME
prodproject=YOUR-PROJECT-NAME
echo $prodproject
echo $consumerproject
#Multiple projects - Update project to support consumer a network
#Inside Cloud Shell, make sure that your project id is set up


gcloud config list project
gcloud config set project [YOUR-PROJECT-NAME]
consumerproject=YOUR-PROJECT-NAME
echo $consumerproject
#From Cloud Shell


gcloud compute networks create vpc-demo-consumer --project=$consumerproject --subnet-mode=custom
#Create Subnet for PSC

#From Cloud Shell


gcloud compute networks subnets create consumer-subnet --project=$consumerproject  --range=10.0.60.0/24 --network=vpc-demo-consumer --region=europe-west2
#Create a static IP address for TCP applications

#From Cloud Shell


gcloud compute addresses create vpc-consumer-psc-tcp --region=europe-west2 --subnet=consumer-subnet --addresses 10.0.60.100
#Create Firewall Rules

#To allow IAP to connect to your VM instances, create a firewall rule that:

#Applies to all VM instances that you want to be accessible by using IAP.
#Allows ingress traffic from the IP range 35.235.240.0/20. This range contains all IP addresses that IAP uses for TCP forwarding.
#From Cloud Shell


gcloud compute firewall-rules create psclab-iap-consumer --network vpc-demo-consumer --allow tcp:22 --source-ranges=35.235.240.0/20 --enable-logging
#Although not required for PSC create a egress firewall rule to monitor consumer PSC traffic to the producers service attachment


gcloud compute --project=$consumerproject firewall-rules create vpc-consumer-psc --direction=EGRESS --priority=1000 --network=vpc-demo-consumer --action=ALLOW --rules=all --destination-ranges=10.0.60.0/24 --enable-logging
#Create Cloud NAT instance
#Cloud NAT is not the same NAT used for PSC. Cloud NAT is used explicitly for internet access to download application packages

#Create Cloud Router

#From Cloud Shell


gcloud compute routers create crnatconsumer --network vpc-demo-consumer --region europe-west2
#Create Cloud NAT

#From Cloud Shell


gcloud compute routers nats create cloudnatconsumer --router=crnatconsumer --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --enable-logging --region europe-west2

#=========================================

#14. Create test instance VM

#From Cloud Shell


gcloud compute instances create test-instance-1 \
    --zone=europe-west2-b \
    --image-family=debian-10 \
    --image-project=debian-cloud \
    --subnet=consumer-subnet --no-address \
    --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install iperf3 -y
apt-get install tcpdump -y'


#=========================================

#15. Create TCP service attachment

#From Cloud Shell


gcloud compute forwarding-rules create vpc-consumer-psc-fr-tcp --region=europe-west2 --network=vpc-demo-consumer --address=vpc-consumer-psc-tcp --target-service-attachment=projects/$prodproject/regions/europe-west2/serviceAttachments/vpc-demo-psc-west2-tcp

#=========================================
#16. Validation

#We will use CURL, TCPDUMP & firewall logs to validate consumer and producer communication.

#Within the Consumer's project the static IP addresses are used to originate communication to the Producer. This mapping of static IP address to Consumer forwarding rule is validated by performing the following syntax.

#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#From the Consumer VPCs Cloud shell identify the TCP forwarding rule and static IP


gcloud compute forwarding-rules describe vpc-consumer-psc-fr-tcp --region europe-west2
#Output:

#IPAddress: 10.0.60.100
#creationTimestamp: '2022-10-30T09:32:31.975-07:00'
#id: '5604723296998463984'
#kind: compute#forwardingRule
#labelFingerprint: 42WmSpB8rSM=
#name: vpc-consumer-psc-fr-tcp
#network: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/global/networks/vpc-demo-consumer
#networkTier: PREMIUM
#pscConnectionId: '54626271866403940'
#pscConnectionStatus: ACCEPTED
#region: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/regions/europe-west2
#selfLink: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/regions/europe-west2/forwardingRules/vpc-consumer-psc-fr-tcp
#serviceDirectoryRegistrations:
#- namespace: goog-psc-default
#target: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/regions/europe-west2/serviceAttachments/vpc-demo-psc-west2-tcp


#================================================

#17. TCP Validation

#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#From the Producer Project, identify "www-01" & "www-02" and launch one SSH session per instance.

#6d0bb8c5cb115876.png

#From "www-01" perform TCPDUMP to monitor NAT


sudo tcpdump -i any net 192.168.0.0/16 -n
#From "www-02" perform TCPDUMP to monitor NAT


sudo tcpdump -i any net 192.168.0.0/16 -n
#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#From the Consumer Project, identify "test-instance-1" and launch two sessions.

#From "test-instance-1" session one perform TCPDUMP to monitor consumer


sudo tcpdump -i any host 10.0.60.100 -n
#From "test-instance-1" session two perform TCP validation


curl -v 10.0.60.100 

#===============================================


#===============================================

#21. Enable Proxy Protocol

#By default, Private Service Connect translates the consumer's source IP address to an address in one of the Private Service Connect subnets in the service producer's VPC network. If you want to see the consumer's original source IP address instead, you can enable PROXY protocol. If PROXY protocol is enabled, you can get the consumer's source IP address and PSC connection ID from the PROXY protocol header

#e9d1c49971b10ed0.png

#Reference to documentation

#Delete the Producers Published Services

#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#From cloud shell delete the TCP service attachments


gcloud compute service-attachments delete vpc-demo-psc-west2-tcp --region=europe-west2 --quiet
#From cloud shell validate service attachments are deleted (Listed 0 items)


gcloud compute service-attachments list
#Create TCP service attachment with proxy protocol enabled


gcloud compute service-attachments create vpc-demo-psc-west2-tcp --region=europe-west2 \
--producer-forwarding-rule=vpc-demo-www-ilb-tcp \
--connection-preference=ACCEPT_AUTOMATIC \
--nat-subnets=vpc-demo-eu-west2-psc-tcp \
--enable-proxy-protocol
#From cloud shell validate service attachments are created with proxy protocol enabled (true)


gcloud compute service-attachments describe vpc-demo-psc-west2-tcp --region=europe-west2 | grep -i enableProxyProtocol:
#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#From cloud shell delete the TCP forwarding rules


gcloud compute forwarding-rules delete vpc-consumer-psc-fr-tcp --region=europe-west2 --quiet
#Recreate the TCP forwarding rules to associate with the previously created (producer) service attachment
#From cloud shell create the TCP forwarding rule


gcloud compute forwarding-rules create vpc-consumer-psc-fr-tcp \
--region=europe-west2 --network=vpc-demo-consumer \
--address=vpc-consumer-psc-tcp \
--target-service-attachment=projects/$prodproject/regions/europe-west2/serviceAttachments/vpc-demo-psc-west2-tcp
#Proxy Protocol Validation
#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#From the Producer Project, identify "www-01" & "www-02" and launch one session per instance.

#6d0bb8c5cb115876.png

#From "www-01" perform TCPDUMP to monitor NAT


sudo tcpdump -nnvvXSs 1514 net 192.168.0.0/16
#From "www-02" perform TCPDUMP to monitor NAT


sudo tcpdump -nnvvXSs 1514 net 192.168.0.0/16
#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#From the Consumer Project, identify "test-instance-1" and launch a single session

#From "test-instance-1" session perform a curl


curl 10.0.60.100 
#Observations - Consumer

#Note that if PROXY Protocol v2 is enabled but the application is not configured to support it, an error message will be displayed if connecting from the client as per the example below. Apache updates are required to accommodate the additional proxy v2 header & not covered in the codelab.

#From "test-instance-1" session CURL will produce an expected 400 Bad requests although the backend query is successful.


#@test-instance-1:~$ curl 10.0.60.100 
#<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
#<html><head>
#<title>400 Bad Request</title>
#</head><body>
#<h1>Bad Request</h1>
#<p>Your browser sent a request that this server could not understand.<br />
#</p>
#<hr>
#<address>Apache/2.4.25 (Debian) Server at www-02.c.deepakmichaelprod.internal Port 80</address>
#Observations - Consumer

#From the backend instance "www-01" or "www-02" the following communication between the TCP NAT subnet and TCP ILB are observed with proxy protocol embedded in the capture.

#In most cases, the 3rd packet in the tcpdump contains the relevant proxy protocol information elements (IE). Optionally, identify the packet with 39 bytes that contain proxy protocol IE.


#192.168.0.3.1025 > 10.0.2.10.80: Flags [P.], cksum 0xb617 (correct), seq 2729454396:2729454435, ack 1311105819, win 28160, length 39: HTTP
#        0x0000:  4500 004f 0000 4000 4006 6df4 c0a8 0003  E..O..@.@.m.....
#        0x0010:  0a00 020a 0401 0050 a2b0 2b3c 4e25 e31b  .......P..+<N%..
#        0x0020:  5018 6e00 b617 0000 0d0a 0d0a 000d 0a51  P.n............Q
#        0x0030:  5549 540a 2111 0017 0a00 3c02 0a00 3c64  UIT.!.....<...<d
#        0x0040:  8138 0050 e000 0800 9b34 d70a 003c 64    .8.P.....4...<d
#Identify the PROXY Protocol Signature: 0d0a0d0a000d0a515549540a in the packet capture

#By identifying the PROXY Protocol Signature, it's possible to break it down and decode the fields as below:

#PROXY Protocol Signature: 0d0a0d0a000d0a515549540a

#Other PROXY Protocol Fields: 21 11 00 17

#IPs and Ports: 0a003c02 0a003c64 8138 0050

#TLV Type: e0

#TLV Length: 00 08

#pscConnection ID: 009b34d70a003c64

#Hex
#Decimal / IP
#PROXY Protocol Signature
#0d0a0d0a000d0a515549540a
#Version, Protocol, Length
#21 11 0017
#Src IP
#0a003c02
#10.0.60.2
#Dst IP
#0a003c64
#10.0.60.100
#Src Port
#8138
#Dst Port
#33080
#0050
#80
#TLV Type (PP2_TYPE_GCP)
#e0
#TLV Length
#0008
#pscConnectionId
#00004dde290a003c64
#43686719580552292
#The pscConnectionId can also be validated by describing the consumer forwarding rule as below, and making sure it matches:

#Note: In the following section, execute configuration updates in the project that contains your Consumer Service

#From cloud shell describe the TCP forwarding rules


gcloud compute forwarding-rules describe vpc-consumer-psc-fr-tcp --region=europe-west2
#Output describing the pscConnectionID

$ gcloud compute forwarding-rules describe vpc-consumer-psc-fr-tcp --region=europe-west2

#IPAddress: 10.0.60.100
#creationTimestamp: '2022-10-30T10:16:45.828-07:00'
#id: '4130535172044165010'
#kind: compute#forwardingRule
#labelFingerprint: 42WmSpB8rSM=
#name: vpc-consumer-psc-fr-tcp
#network: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/global/networks/vpc-demo-consumer
#networkTier: PREMIUM
#pscConnectionId: '54626271866403940'
#pscConnectionStatus: ACCEPTED
#region: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/regions/europe-west2
#selfLink: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/regions/europe-west2/forwardingRules/vpc-consumer-psc-fr-tcp
#serviceDirectoryRegistrations:
#- namespace: goog-psc-default
#target: https://www.googleapis.com/compute/v1/projects/my-kubernetes-codelab-102022/regions/europe-west2/serviceAttachments/vpc-demo-psc-west2-tcp



#==============================================

#23. Cleanup steps

#Producer network clean up steps

#Note: In the following section, execute configuration updates in the project that contains your Producer Service

#From a single cloud shell in the Producer project terminal delete lab components


gcloud compute routers nats delete cloudnatprod --router=crnatprod --region=us-west2 --quiet

gcloud compute routers delete crnatprod --region=us-west2 --quiet

gcloud compute instances delete www-01 --zone=us-west2-a --quiet

gcloud compute instances delete www-02 --zone=us-west2-a --quiet

gcloud compute service-attachments delete vpc-demo-psc-west2-tcp --region=us-west2 --quiet

gcloud compute forwarding-rules delete vpc-demo-www-ilb-tcp --region=us-west2 --quiet

gcloud compute backend-services delete vpc-demo-www-be-tcp --region=us-west2 --quiet

gcloud compute instance-groups unmanaged delete vpc-demo-ig-www --zone=us-west2-a --quiet

gcloud compute health-checks delete hc-http-80 --quiet

gcloud compute firewall-rules delete vpc-demo-allowpsc-tcp --quiet

gcloud compute firewall-rules delete vpc-demo-health-checks --quiet

gcloud compute firewall-rules delete psclab-iap-prod --quiet

gcloud compute networks subnets delete vpc-demo-us-west2 --region=us-west2 --quiet

gcloud compute networks subnets delete vpc-demo-us-west2-psc-tcp --region=us-west2 --quiet

gcloud compute networks delete vpc-demo-producer --quiet
Note: In the following section, execute configuration updates in the project that contains your Consumer Service

Consumer network clean up steps

From a single cloud shell in the Producer project terminal delete lab components


gcloud compute routers nats delete cloudnatconsumer --router=crnatconsumer --region=us-west2 --quiet

gcloud compute routers delete crnatconsumer --region=us-west2 --quiet

gcloud compute instances delete test-instance-1 --zone=us-west2-a --quiet

gcloud compute forwarding-rules delete vpc-consumer-psc-fr-tcp --region=us-west2 --quiet

gcloud compute addresses delete vpc-consumer-psc-tcp --region=us-west2 --quiet

gcloud compute firewall-rules delete psclab-iap-consumer --quiet

gcloud compute networks subnets delete consumer-subnet --region=us-west2 --quiet

gcloud compute firewall-rules delete vpc-consumer-psc --quiet

gcloud compute networks delete vpc-demo-consumer --quiet

