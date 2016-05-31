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
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [ "ec2:*", "elasticloadbalancing:*" ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:ListImages",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": [
        "${aws_ecr_repository.kubernetes-master-pki-repository.arn}",
        "${aws_ecr_repository.kubernetes-node-pki-repository.arn}"
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
      "Action": [ "ec2:Describe*", "ec2:AttachVolume", "ec2:DetachVolume" ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:ListImages"
      ],
      "Resource": "${aws_ecr_repository.kubernetes-node-pki-repository.arn}"
    }
  ]
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
