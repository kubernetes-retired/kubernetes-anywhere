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

resource "aws_launch_configuration" "kubernetes-node-group" {
    name                        = "kubernetes-node-group-${var.cluster}"
    image_id                    = "${module.ubuntu_ami.ami_id}"
    instance_type               = "${var.node_instance_type}"
    iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-node.name}"
    ebs_optimized               = false
    enable_monitoring           = true
    key_name                    = "${var.ec2_key_name}"
    security_groups             = ["${aws_security_group.kubernetes-main-sg.id}"]
    associate_public_ip_address = true
    user_data                   = "${file("${path.module}/${var.cluster_config_flavour}-user-data.yaml")}"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 32
        delete_on_termination = true
    }
}

resource "aws_autoscaling_group" "kubernetes-node-group" {
    name                      = "kubernetes-node-group-${var.cluster}"
    launch_configuration      = "${aws_launch_configuration.kubernetes-node-group.name}"
    vpc_zone_identifier       = ["${aws_subnet.kubernetes-subnet.id}"]
    desired_capacity          = 3
    max_size                  = 3
    min_size                  = 3
    health_check_grace_period = 0
    health_check_type         = "EC2"

    tag {
        key                  = "KubernetesCluster"
        value                = "kubernetes-${var.cluster}"
        propagate_at_launch  = true
    }

    tag {
        key                  = "Name"
        value                = "kubernetes-node"
        propagate_at_launch  = true
    }
}

resource "aws_instance" "kubernetes-master" {
    ami                         = "${module.ubuntu_ami.ami_id}"
    ebs_optimized               = false
    instance_type               = "${var.master_instance_type}"
    monitoring                  = false
    key_name                    = "${var.ec2_key_name}"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-main-sg.id}"]
    associate_public_ip_address = true
    source_dest_check           = true
    iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-master.name}"
    user_data                   = "${file("${path.module}/${var.cluster_config_flavour}-user-data.yaml")}"

    ebs_block_device {
        device_name           = "/dev/sdb"
        volume_type           = "gp2"
        volume_size           = 20
        delete_on_termination = true
    }

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }

    tags {
        "KubernetesCluster" = "kubernetes-${var.cluster}"
        "Name"              = "kubernetes-master"
    }
}

resource "aws_instance" "kubernetes-etcd" {
    count                       = 3
    ami                         = "${module.ubuntu_ami.ami_id}"
    ebs_optimized               = false
    instance_type               = "${var.etcd_instance_type}"
    monitoring                  = false
    key_name                    = "${var.ec2_key_name}"
    subnet_id                   = "${aws_subnet.kubernetes-subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.kubernetes-main-sg.id}"]
    associate_public_ip_address = true
    source_dest_check           = true
    iam_instance_profile        = "${aws_iam_instance_profile.kubernetes-etcd.name}"
    user_data                   = "${file("${path.module}/${var.cluster_config_flavour}-user-data.yaml")}"

    ebs_block_device {
        device_name           = "/dev/sdb"
        volume_type           = "gp2"
        volume_size           = 20
        delete_on_termination = true
    }

    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }

    tags {
        "KubernetesCluster"      = "kubernetes-${var.cluster}"
        "Name"                   = "kubernetes-etcd"
        "KubernetesEtcdNodeName" = "etcd${count.index + 1}"
    }
}

resource "aws_ecr_repository" "kubernetes-master-pki-repository" {
  name = "kubernetes-${var.cluster}/master/pki"
}

resource "aws_ecr_repository" "kubernetes-node-pki-repository" {
  name = "kubernetes-${var.cluster}/node/pki"
}
