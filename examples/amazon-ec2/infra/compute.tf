resource "aws_autoscaling_group" "kubernetes-minion-group" {
    desired_capacity          = 4
    health_check_grace_period = 0
    health_check_type         = "EC2"
    launch_configuration      = "kubernetes-minion-group"
    max_size                  = 4
    min_size                  = 4
    name                      = "kubernetes-minion-group"
    vpc_zone_identifier       = ["${aws_subnet.kubernetes-subnet.id}"]

    tag {
        key   = "KubernetesCluster"
        value = "kubernetes"
        propagate_at_launch = true
        key   = "Name"
        value = "kubernetes-minion"
        propagate_at_launch = true
        key   = "Role"
        value = "kubernetes-minion"
        propagate_at_launch = true
    }
}

resource "aws_instance" "kubernetes-node-1" {
    ami                         = "ami-33566d03"
    availability_zone           = "us-west-2a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = true
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-node.id}"]
    associate_public_ip_address = true
    private_ip                  = "172.20.0.33"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 32
        iops                  = 96
        delete_on_termination = true
    }

    tags {
        "Role" = "kubernetes-minion"
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-minion"
        "aws:autoscaling:groupName" = "kubernetes-minion-group"
    }
}

resource "aws_instance" "kubernetes-node-2" {
    ami                         = "ami-33566d03"
    availability_zone           = "us-west-2a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = true
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-node.id}"]
    associate_public_ip_address = true
    private_ip                  = "172.20.0.34"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 32
        iops                  = 96
        delete_on_termination = true
    }

    tags {
        "aws:autoscaling:groupName" = "kubernetes-minion-group"
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-minion"
        "Role" = "kubernetes-minion"
    }
}

resource "aws_instance" "kubernetes-node-3" {
    ami                         = "ami-33566d03"
    availability_zone           = "us-west-2a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = true
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-node.id}"]
    associate_public_ip_address = true
    private_ip                  = "172.20.0.35"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 32
        iops                  = 96
        delete_on_termination = true
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-minion"
        "aws:autoscaling:groupName" = "kubernetes-minion-group"
        "Role" = "kubernetes-minion"
    }
}

resource "aws_instance" "kubernetes-node-4" {
    ami                         = "ami-33566d03"
    availability_zone           = "us-west-2a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = true
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-node.id}"]
    associate_public_ip_address = true
    private_ip                  = "172.20.0.36"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 32
        iops                  = 96
        delete_on_termination = true
    }

    tags {
        "aws:autoscaling:groupName" = "kubernetes-minion-group"
        "Name" = "kubernetes-minion"
        "Role" = "kubernetes-minion"
        "KubernetesCluster" = "kubernetes"
    }
}

resource "aws_instance" "kubernetes-master" {
    ami                         = "ami-33566d03"
    availability_zone           = "us-west-2a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = false
    key_name                    = "terraform"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-master.id}"]
    associate_public_ip_address = true
    private_ip                  = "172.20.0.9"
    source_dest_check           = true

    ebs_block_device {
        device_name           = "/dev/sdb"
        snapshot_id           = ""
        volume_type           = "gp2"
        volume_size           = 20
        iops                  = 60
        delete_on_termination = false
    }

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        iops                  = 24
        delete_on_termination = true
    }

    tags {
        "KubernetesCluster" = "kubernetes"
        "Name" = "kubernetes-master"
        "Role" = "kubernetes-master"
    }
}
