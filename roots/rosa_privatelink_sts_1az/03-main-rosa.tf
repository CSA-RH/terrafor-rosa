
output "next_steps" {
  value = <<EOF


***** Next steps *****


* Create your ROSA cluster:

$ rosa create cluster --region ${var.aws_region} --version ${var.ocp_version} --enable-autoscaling --min-replicas 3 --max-replicas 6 --private-link --cluster-name=${var.cluster_name} --machine-cidr=${var.cluster_cidr} --subnet-ids=${aws_subnet.rosa-subnet-priv[var.availability_zones[0]].id} --tags=Owner:${var.cluster_owner_tag},Environment:${var.environment} --sts -y
$ rosa create operator-roles --cluster rosa-csa-test -m auto -y
$ rosa create oidc-provider --cluster rosa-csa-test -m auto -y

* create a route53 zone association for the egress vpc

$ ZONE=$(aws route53 list-hosted-zones-by-vpc --vpc-id ${aws_vpc.rosa-vpc.id} --vpc-region ${var.aws_region} --query 'HostedZoneSummaries[*].HostedZoneId' --output text)
  aws route53 associate-vpc-with-hosted-zone  --hosted-zone-id $ZONE --vpc VPCId=${aws_vpc.egress-vpc.id},VPCRegion=${var.aws_region} --output text

* Create an Admin user:

$ rosa create admin -c ${var.cluster_name}

* Run the command provided above to log into the cluster

* Find the URL of the cluster's console and log into it via your web browser
$ rosa describe cluster -c ${var.cluster_name} -o json | jq -r .console.url

* Setup SSH tunneling 
 - First update /etc/hosts to point the openshift domains to localhost:

    127.0.0.1 api.$YOUR_OPENSHIFT_DNS
    127.0.0.1 console-openshift-console.apps.$YOUR_OPENSHIFT_DNS
    127.0.0.1 oauth-openshift.apps.$YOUR_OPENSHIFT_DNS

- Use public IP address from Terraform output to connect to bastion host, so let's get the private key and operate:

  $ terraform output -raw bastion_private_key > bastion.key

  SSH to that instance, tunnelling traffic for the appropriate hostnames:

  $ sudo ssh -i PATH/TO/bastion.key \
    -L 6443:api.$YOUR_OPENSHIFT_DNS:6443 \
    -L 443:console-openshift-console.apps.$YOUR_OPENSHIFT_DNS:443 \
    -L 80:console-openshift-console.apps.$YOUR_OPENSHIFT_DNS:80 \
     ec2-user@${aws_instance.egress-vpc-bastion.public_ip}

EOF
  description = "ROSA cluster creation command"
}


 
