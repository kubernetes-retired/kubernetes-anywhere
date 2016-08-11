# Copyright 2016 The Kubernetes Authors All rights reserved.
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

variable "cluster" {
   description = "Kubernetes cluster suffix (set this if you wish to deploy more then one cluster)"
   default     = "anywhere"
}

variable "node_instance_type" {
   description = "EC2 instance type for Kubernetes worker nodes"
   default     = "m3.xlarge"
}

variable "master_instance_type" {
    description = "EC2 instance type for Kubernetes master node(s)"
    default     = "m3.xlarge"
}

variable "ec2_key_name" {
   description = "SSH key name to use for all of EC2 instances"
   default     = "kubernetes-anywhere"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "aws_region" {
   description = "The EC2 region where to deploy Kubernetes cluster"
   default     = "us-east-1"
}

variable "phase2_implementation" {
   description = "Flavour of the cluster config (secure or simple)"
   default     = "simple-weave-single-master"
}

variable "node_count" {
  description  = "Number of nodes in the cluster"
  default      = 2
}

variable "standalone_etcd_cluster_size" {
  description  = "Number of etcd nodes in the cluster for standalone etcd"
  # zero means it will not be configured at all, yet for it to work,
  # one has to pick right value of `phase2_implementation`
  default      = 0
}

variable "standalone_etcd_instance_type" {
    description = "EC2 instance type for etcd node(s) in standalone etcd mode"
    default     = "t2.large"
}
