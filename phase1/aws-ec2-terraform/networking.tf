# Copyright 2015-2016 Weaveworks Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

resource "aws_vpc" "kubernetes-vpc" {
    cidr_block           = "172.20.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags {
        "KubernetesCluster" = "kubernetes-${var.cluster}"
        "Name"              = "kubernetes-vpc"
    }
}

resource "aws_internet_gateway" "kubernetes-igw" {
    vpc_id = "${aws_vpc.kubernetes-vpc.id}"

    tags {
        "KubernetesCluster" = "kubernetes-${var.cluster}"
        "Name"              = "kubernetes-igw"
    }
}

resource "aws_security_group" "kubernetes-main-sg" {
    name        = "kubernetes-${var.cluster}"
    description = "Kubernetes Anywhere security group applied to all nodes"
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
        "KubernetesCluster" = "kubernetes-${var.cluster}"
        "Name"              = "kubernetes-main-sg"
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
        "KubernetesCluster" = "kubernetes-${var.cluster}"
        "Name"              = "kubernetes-acl"
    }
}

resource "aws_subnet" "kubernetes-subnet" {
    vpc_id                  = "${aws_vpc.kubernetes-vpc.id}"
    cidr_block              = "172.20.0.0/24"
    map_public_ip_on_launch = false

    tags {
        "KubernetesCluster" = "kubernetes-${var.cluster}"
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
