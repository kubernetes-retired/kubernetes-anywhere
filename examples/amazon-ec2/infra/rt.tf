resource "aws_route_table" "rtb-7446aa10" {
    vpc_id     = "vpc-5fb9ae3a"

    tags {
    }
}

resource "aws_route_table" "rtb-7846aa1c" {
    vpc_id     = "vpc-5fb9ae3a"

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

