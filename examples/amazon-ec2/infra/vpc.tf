resource "aws_vpc" "kubernetes-vpc" {
    cidr_block           = "172.20.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-vpc"
    }
}

