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

resource "aws_security_group" "sg-796e961e-default" {
    name        = "default"
    description = "default VPC security group"
    vpc_id      = "${aws_vpc.kubernetes-vpc.id}"

    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        self            = true
    }


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

}

resource "aws_security_group" "sg-5f6e9638-kubernetes-master-kubernetes" {
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

resource "aws_security_group" "sg-5b6e963c-kubernetes-minion-kubernetes" {
    name        = "kubernetes-minion-kubernetes"
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

resource "aws_network_acl" "acl-9e9c82fb" {
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

resource "aws_route_table" "rtb-7446aa10" {
    vpc_id     = "${aws_vpc.kubernetes-vpc.id}"

    tags {
    }
}

resource "aws_route_table" "rtb-7846aa1c" {
    vpc_id     = "${aws_vpc.kubernetes-vpc.id}"

    route {
        cidr_block = "10.244.2.0/24"
        instance_id = "i-358b6bed"
        network_interface_id = "eni-b11e6efa"
    }

    route {
        cidr_block = "10.244.0.0/24"
        instance_id = "i-328b6bea"
        network_interface_id = "eni-b31e6ef8"
    }

    route {
        cidr_block = "10.246.0.0/24"
        instance_id = "i-388868e0"
        network_interface_id = "eni-e31d6da8"
    }

    route {
        cidr_block = "10.244.3.0/24"
        instance_id = "i-348b6bec"
        network_interface_id = "eni-b21e6ef9"
    }

    route {
        cidr_block = "10.244.1.0/24"
        instance_id = "i-378b6bef"
        network_interface_id = "eni-bc1e6ef7"
    }

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "igw-aa9cd8cf"
    }

    tags {
        "KubernetesCluster" = "kubernetes"
    }
}

resource "aws_route_table_association" "rtb-7846aa1c-rtbassoc-12842276" {
    route_table_id = "rtb-7846aa1c"
    subnet_id = "${aws_subnet.kubernetes-subnet.id}"
}

resource "aws_network_interface" "eni-b11e6efa" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.34"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-358b6bed"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-b31e6ef8" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.35"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-328b6bea"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-e31d6da8" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.9"]
    security_groups   = ["sg-5f6e9638"]
    source_dest_check = true
    attachment {
        instance     = "i-388868e0"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-bc1e6ef7" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.36"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-378b6bef"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-b21e6ef9" {
    subnet_id         = "${aws_subnet.kubernetes-subnet.id}"
    private_ips       = ["172.20.0.33"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-348b6bec"
        device_index = 0
    }
}

