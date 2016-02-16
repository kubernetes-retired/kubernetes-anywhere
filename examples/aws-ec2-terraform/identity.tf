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

resource "aws_iam_role" "kubernetes-master" {
    name               = "kubernetes-master-${var.cluster}"
    path               = "/"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role" "kubernetes-node" {
    name               = "kubernetes-node-${var.cluster}"
    path               = "/"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "kubernetes-master" {
    name   = "kubernetes-master-${var.cluster}"
    role   = "${aws_iam_role.kubernetes-master.name}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:*"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::kubernetes-*"
      ]
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "kubernetes-node" {
    name   = "kubernetes-node-${var.cluster}"
    role   = "${aws_iam_role.kubernetes-node.name}"
    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::kubernetes-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "ec2:Describe*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:AttachVolume",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DetachVolume",
      "Resource": "*"
    }
  ]
}
POLICY
}
