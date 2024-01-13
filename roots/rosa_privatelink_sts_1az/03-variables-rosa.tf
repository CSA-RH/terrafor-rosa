variable "cluster_name" {
    default = "rosa-csa-test"
    description   = "Cluster name"
    type = string
}

variable "ocp_version" {
    default = "4.12.46"
    description   = "OCP Version to Install."
    type = string
}

variable "url" {
  type      = string
  default   = "https://api.openshift.com"
}


  