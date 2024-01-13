
output "next_steps" {
  value = <<EOF


***** Next steps *****


* Create your ROSA cluster:

$ rosa create cluster --region ${var.aws_region} --version ${var.ocp_version} --enable-autoscaling --min-replicas 3 --max-replicas 6 --private-link --cluster-name=${var.cluster_name} --machine-cidr=${var.cluster_cidr} --subnet-ids=${aws_subnet.rosa-subnet-priv[var.availability_zones[0]].id} --tags=Owner:${var.cluster_owner_tag},Environment:${var.environment} --sts -y


* create a route53 zone association for the egress vpc

$ ZONE=$(aws route53 list-hosted-zones-by-vpc --vpc-id ${aws_vpc.rosa-vpc.id} --vpc-region ${var.aws_region} --query 'HostedZoneSummaries[*].HostedZoneId' --output text)
  aws route53 associate-vpc-with-hosted-zone  --hosted-zone-id $ZONE --vpc VPCId=${aws_vpc.egress-vpc.id},VPCRegion=${var.aws_region} --output text

* Create a sshuttle VPN via your bastion:

$ sshuttle --dns -NHr ec2-user@${aws_instance.egress-vpc-bastion.public_ip} ${var.tgw_cidr_block}

* Create an Admin user:

$ rosa create admin -c ${var.cluster_name}

* Run the command provided above to log into the cluster

* Find the URL of the cluster's console and log into it via your web browser
$ rosa describe cluster -c ${var.cluster_name} -o json | jq -r .console.url

EOF
  description = "ROSA cluster creation command"
}


 