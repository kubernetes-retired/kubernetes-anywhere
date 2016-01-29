resource "aws_subnet" "subnet-ed556b9a" {
    vpc_id                  = "vpc-5fb9ae3a"
    cidr_block              = "172.20.0.0/24"
    availability_zone       = "us-west-2a"
    map_public_ip_on_launch = false

    tags {
        "KubernetesCluster" = "kubernetes"
    }
}

