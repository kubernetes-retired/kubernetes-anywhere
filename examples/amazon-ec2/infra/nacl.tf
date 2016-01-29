resource "aws_network_acl" "acl-9e9c82fb" {
    vpc_id     = "vpc-5fb9ae3a"
    subnet_ids = ["subnet-ed556b9a"]

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

