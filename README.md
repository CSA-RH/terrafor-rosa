# ROSA w/ private link and STS

The code in this repo will create the necesary AWS resources required to deploy Red Hat OpenShift Service on AWS (ROSA) cluster using private link and Secure Token Service.
It will create the cluster in a 3 AZs.

This Terraform template will deploy a Hub and Spoke architecture, with an egress VPC. For internet access, the trafic will flow towards the egress VPC.
## Resources

### For the ROSA cluster
 * ROSA VPC
 * Private subnets only
 * Egress traffic is routed to the TGW.
 * Routing tables, rules and association for each subnet
 * Bastion Host 1. configured on the public subnet of the ROSA VPC.

### Hub - TGW
 * Attachments to the privete subnetworks

### Egress VPC
 * EGRESS VPC
 * Internet GW
 * EIP
 * NAT GW
 * Bastion Host2

### Two Bastion hosts are deployed


## Diagram

![Quick Drawing](./images/quick-drawing.jpg)


## Prerequisites

 * The terraform AWS provider will need the user to be [authenticated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration)
 * The terraform CLI
 * The ROSA CLI

## Deploy Environment
The infrastructure deployment is divided in two diferent phases. 
 * First phase: consists deploying Terraform plan to create the auxiliary infrastructure. By auxiliary infrasctructure I mean: the VPCs (rosa and egress), Transit GW, NAT GW, IGW, configure the Routing tables, etc... 

 * Second phase: Use the ROSA cmd cli to create the rosa cluster.

### Deploy Auxiliary Infrastructure - First Phase
1. Clone this repo
```
$ git clone https://github.com/luisevm/terraform-rosa.git
```

2. Go to path
```
cd terraform-rosa/roots/rosa_privatelink_sts_3azs
```

4. Rename the file terraform.tfvars.example to terraform.tfvars, and configure in the file the SSH public Key parameter
```
mv terraform.tfvars.example terraform.tfvars
vi terraform.tfvars
```

5. Deploy AWS resources
```
terraform init
terraform plan -out "rosa.plan"
terraform apply "rosa.plan"
```

### Deploy ROSA Cluster - Second Phase

 * Run the script that is displayed in the output of terraform apply command.

```
#!/bin/bash

export REGION=eu-central-1
export SUBNET=subnet-0ok0f8...,subnet-046ac...,subnet-08hjj...
export OWNER=lmartinh
export CLUSTER_NAME=mycluster01
export VERSION=4.12.14
export ROSA_ENVIRONMENT=Test

rosa create ocm-role --mode auto -y --admin
rosa create user-role --mode auto -y
rosa create account-roles --mode auto -y
rosa create cluster --region $REGION --version $VERSION --enable-autoscaling --min-replicas 3 --max-replicas 6 --private-link --cluster-name=$CLUSTER_NAME --machine-cidr=10.1.0.0/16 --subnet-ids=$SUBNET --tags=Owner:$OWNER,Environment:$ROSA_ENVIRONMENT --sts -y --multi-az
rosa create operator-roles --cluster $CLUSTER_NAME -y --mode auto
rosa create oidc-provider --cluster $CLUSTER_NAME -y --mode auto
```

## SSH into the bastion host
//     (authorized_key = pub)                       
// (manualmiente generate keys (pub+priv))              (Terraform keys (pub+priv) )                   (authorized_key = pub)
// Cliente (ssh -i priv ec2-user@bastion1)    ->  Bastion1 (ssh -i priv ec2-user@bastion2)   ->         Bastion2 -> OCP

1.Get private key generated by Terraform and used for the two Bastion hosts and save it to a file
```
terraform output -raw private_key > id_rsa
chmod 400 id_rsa
```

2..Copy the Private SSH key to the Bastion_egress
```
scp -i ./id_rsa ./id_rsa ec2-user@$IP_BASTION_EGRESS:/home/ec2-user/.ssh
```

3.Note the DNS of the OCP API
```
rosa describe cluster -c $CLUSTER_NAME
```

4.Create a ROSA admin user and save the login command for use later
```
rosa create admin -c $CLUSTER_NAME
```

5.Configure the client hosts file
```
vi /etc/hosts

127.0.0.1 api.$YOUR_OPENSHIFT_DNS
127.0.0.1 console-openshift-console.apps.$YOUR_OPENSHIFT_DNS
127.0.0.1 oauth-openshift.apps.$YOUR_OPENSHIFT_DNS
```

6.Establish two SSH tunnels, Bastion_egress and Bastion_rosa
cliente  ->  Bastion_egress  ->  Bastion_rosa -> OCP
```
export IP_BASTION_EGRESS=your_ip
export IP_BASTION_ROSA=10.1.21.100

export local_host_port=30000
export user=ec2-user
export host1=$IP_BASTION_EGRESS
export host1_port=30000
export host2=$IP_BASTION_ROSA
export host2_port=30000

# Tunnel from localhost to host1 and from host1 to host2
ssh -tt -L $local_host_port:localhost:$host1_port $user@$host1 -i id_rsa \
ssh -tt -L $host1_port:localhost:$host2_port $user@$host2
```


