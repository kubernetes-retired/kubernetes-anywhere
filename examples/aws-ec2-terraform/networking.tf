resource "aws_vpc" "kubernetes-vpc" {
    cidr_block           = "172.20.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name"              = "kubernetes-vpc"
    }
}

resource "aws_internet_gateway" "kubernetes-igw" {
    vpc_id = "${aws_vpc.kubernetes-vpc.id}"

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name"              = "kubernetes-igw"
    }
}

resource "aws_security_group" "kubernetes-master" {
    name        = "kubernetes-master-kubernetes"
    description = "Kubernetes security group applied to master nodes"
    vpc_id      = "${aws_vpc.kubernetes-vpc.id}"

    ## TODO: figure out whether these are red herrings or what
    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        self            = true
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 4040
        to_port         = 4040
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 6783
        to_port         = 6783
        protocol        = "tcp"
        cidr_blocks     = ["172.20.0.0/16"]
    }

    ingress {
        from_port       = 6783
        to_port         = 6784
        protocol        = "udp"
        cidr_blocks     = ["172.20.0.0/16"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name"              = "kubernetes-master-sg"
    }
}

resource "aws_security_group" "kubernetes-node" {
    name        = "kubernetes-node"
    description = "Kubernetes security group applied to minion nodes"
    vpc_id      = "${aws_vpc.kubernetes-vpc.id}"

    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        self            = true
    }

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 4040
        to_port         = 4040
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 6783
        to_port         = 6783
        protocol        = "tcp"
        cidr_blocks     = ["172.20.0.0/16"]
    }

    ingress {
        from_port       = 6783
        to_port         = 6784
        protocol        = "udp"
        cidr_blocks     = ["172.20.0.0/16"]
    }

    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name"              = "kubernetes-node-sg"
    }
}

resource "aws_network_acl" "kubernetes-acl" {
    vpc_id     = "${aws_vpc.kubernetes-vpc.id}"
    subnet_ids = ["${aws_subnet.kubernetes-subnet.id}"]

    ingress {
        from_port  = 0
        to_port    = 0
        rule_no    = 100
        action     = "allow"
        protocol   = "-1"
        cidr_block = "0.0.0.0/0"
    }

    egress {
        from_port  = 0
        to_port    = 0
        rule_no    = 100
        action     = "allow"
        protocol   = "-1"
        cidr_block = "0.0.0.0/0"
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name"              = "kubernetes-acl"
    }
}

resource "aws_subnet" "kubernetes-subnet" {
    vpc_id                  = "${aws_vpc.kubernetes-vpc.id}"
    cidr_block              = "172.20.0.0/24"
    map_public_ip_on_launch = false

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name"              = "kubernetes-subnet"
    }
}

resource "aws_route_table" "kubernetes-routes" {
    vpc_id     = "${aws_vpc.kubernetes-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.kubernetes-igw.id}"
    }
}

resource "aws_route_table_association" "kubernetes-routes" {
    route_table_id = "${aws_route_table.kubernetes-routes.id}"
    subnet_id = "${aws_subnet.kubernetes-subnet.id}"
}
