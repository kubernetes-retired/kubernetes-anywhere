resource "aws_network_interface" "eni-b11e6efa" {
    subnet_id         = "subnet-ed556b9a"
    private_ips       = ["172.20.0.34"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-358b6bed"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-b31e6ef8" {
    subnet_id         = "subnet-ed556b9a"
    private_ips       = ["172.20.0.35"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-328b6bea"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-e31d6da8" {
    subnet_id         = "subnet-ed556b9a"
    private_ips       = ["172.20.0.9"]
    security_groups   = ["sg-5f6e9638"]
    source_dest_check = true
    attachment {
        instance     = "i-388868e0"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-bc1e6ef7" {
    subnet_id         = "subnet-ed556b9a"
    private_ips       = ["172.20.0.36"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-378b6bef"
        device_index = 0
    }
}

resource "aws_network_interface" "eni-b21e6ef9" {
    subnet_id         = "subnet-ed556b9a"
    private_ips       = ["172.20.0.33"]
    security_groups   = ["sg-5b6e963c"]
    source_dest_check = false
    attachment {
        instance     = "i-348b6bec"
        device_index = 0
    }
}

