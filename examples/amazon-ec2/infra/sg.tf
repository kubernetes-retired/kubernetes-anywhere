resource "aws_security_group" "sg-796e961e-default" {
    name        = "default"
    description = "default VPC security group"
    vpc_id      = "vpc-5fb9ae3a"

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
    vpc_id      = "vpc-5fb9ae3a"

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
    vpc_id      = "vpc-5fb9ae3a"

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

