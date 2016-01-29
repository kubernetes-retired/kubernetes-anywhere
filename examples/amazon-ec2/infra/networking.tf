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

resource "aws_internet_gateway" "kubernetes-igw" {
    vpc_id = "${aws_vpc.kubernetes-vpc.id}"
}

resource "aws_security_group" "kubernetes-master" {
    name        = "kubernetes-master-kubernetes"
    description = "Kubernetes security group applied to master nodes"
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
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags {
        "KubernetesCluster" = "kubernetes"
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


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags {
        "KubernetesCluster" = "kubernetes"
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
    }
}

resource "aws_subnet" "kubernetes-subnet" {
    vpc_id                  = "${aws_vpc.kubernetes-vpc.id}"
    cidr_block              = "172.20.0.0/24"
    availability_zone       = "us-west-2a"
    map_public_ip_on_launch = false

    tags {
        "KubernetesCluster" = "kubernetes"
    }
}

resource "aws_route_table" "kubernetes-routes" {
    vpc_id     = "${aws_vpc.kubernetes-vpc.id}"

    route {
        cidr_block = "10.244.0.0/24"
        instance_id = "${aws_instance.kubernetes-node-1.id}"
        network_interface_id = "${aws_network_interface.kubernetes-node-1.id}"
    }

    route {
        cidr_block = "10.244.1.0/24"
        instance_id = "${aws_instance.kubernetes-node-2.id}"
        network_interface_id = "${aws_network_interface.kubernetes-node-2.id}"
    }

    route {
        cidr_block = "10.244.2.0/24"
        instance_id = "${aws_instance.kubernetes-node-3.id}"
        network_interface_id = "${aws_network_interface.kubernetes-node-3.id}"
    }

    route {
        cidr_block = "10.244.3.0/24"
        instance_id = "${aws_instance.kubernetes-node-4.id}"
        network_interface_id = "${aws_network_interface.kubernetes-node-4.id}"
    }

    route {
        cidr_block = "10.246.0.0/24"
        instance_id = "${aws_instance.kubernetes-master.id}"
        network_interface_id = "${aws_network_interface.kubernetes-master.id}"
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.kubernetes-igw.id}"
    }

    tags {
        "KubernetesCluster" = "kubernetes"
    }
}

resource "aws_route_table_association" "kubernetes-routes" {
    route_table_id = "${aws_route_table.kubernetes-routes.id}"
    subnet_id = "${aws_subnet.kubernetes-subnet.id}"
}

resource "aws_network_interface" "kubernetes-node-1" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.33"]
    security_groups   = ["${aws_security_group.kubernetes-node.id}"]
    source_dest_check = false
    attachment {
        instance     = "${aws_instance.kubernetes-node-1.id}"
        device_index = 0
    }
}

resource "aws_network_interface" "kubernetes-node-2" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.34"]
    security_groups   = ["${aws_security_group.kubernetes-node.id}"]
    source_dest_check = false
    attachment {
        instance     = "${aws_instance.kubernetes-node-2.id}"
        device_index = 0
    }
}

resource "aws_network_interface" "kubernetes-node-3" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.35"]
    security_groups   = ["${aws_security_group.kubernetes-node.id}"]
    source_dest_check = false
    attachment {
        instance     = "${aws_instance.kubernetes-node-3.id}"
        device_index = 0
    }
}

resource "aws_network_interface" "kubernetes-node-4" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.36"]
    security_groups   = ["${aws_security_group.kubernetes-node.id}"]
    source_dest_check = false
    attachment {
        instance     = "${aws_instance.kubernetes-node-4.id}"
        device_index = 0
    }
}

resource "aws_network_interface" "kubernetes-master" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.9"]
    security_groups   = ["${aws_security_group.kubernetes-master.id}"]
    source_dest_check = true
    attachment {
        instance     = "${aws_instance.kubernetes-master.id}"
        device_index = 0
    }
}
