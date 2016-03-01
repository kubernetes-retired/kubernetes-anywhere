resource "aws_iam_instance_profile" "kubernetes-master" {
    name  = "kubernetes-master-${var.cluster}"
    path  = "/"
    roles = ["${aws_iam_role.kubernetes-master.name}"]
}

resource "aws_iam_instance_profile" "kubernetes-node" {
    name  = "kubernetes-node-${var.cluster}"
    path  = "/"
    roles = ["${aws_iam_role.kubernetes-node.name}"]
}

resource "aws_iam_instance_profile" "kubernetes-etcd" {
    name  = "kubernetes-etcd-${var.cluster}"
    path  = "/"
    roles = ["${aws_iam_role.kubernetes-etcd.name}"]
}

variable "iam_common_assume_role_policy" {
   default = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
     "Effect": "Allow",
     "Principal": { "Service": "ec2.amazonaws.com" },
     "Action": "sts:AssumeRole"
  }]
}
POLICY
}

resource "aws_iam_role" "kubernetes-master" {
    name               = "kubernetes-master-${var.cluster}"
    path               = "/"
    assume_role_policy = "${var.iam_common_assume_role_policy}"
}

resource "aws_iam_role" "kubernetes-node" {
    name               = "kubernetes-node-${var.cluster}"
    path               = "/"
    assume_role_policy = "${var.iam_common_assume_role_policy}"
}

resource "aws_iam_role" "kubernetes-etcd" {
    name               = "kubernetes-etcd-${var.cluster}"
    path               = "/"
    assume_role_policy = "${var.iam_common_assume_role_policy}"
}

resource "aws_iam_role_policy" "kubernetes-master" {
    name   = "kubernetes-master-${var.cluster}"
    role   = "${aws_iam_role.kubernetes-master.name}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Action": [ "ec2:*", "elasticloadbalancing:*" "ecr:*" ],
      "Resource": "*"
   }]
}
POLICY
}

resource "aws_iam_role_policy" "kubernetes-node" {
    name   = "kubernetes-node-${var.cluster}"
    role   = "${aws_iam_role.kubernetes-node.name}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ec2:Describe*", "ec2:AttachVolume", "ec2:DetachVolume",
      "ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage",
      "ecr:DescribeRepositories", "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy", "ecr:ListImages"
    ],
    "Resource": "*"
  }]
}
POLICY
}

resource "aws_iam_role_policy" "kubernetes-etcd" {
    name   = "kubernetes-etcd-${var.cluster}"
    role   = "${aws_iam_role.kubernetes-etcd.name}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow", "Action": "ec2:Describe*", "Resource": "*"
  }]
}
POLICY
}
