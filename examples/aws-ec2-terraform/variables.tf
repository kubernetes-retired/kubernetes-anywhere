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

variable "etcd_instance_type" {
    description = "EC2 instance type for etcd node(s)"
    default     = "t2.large"
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

variable "cluster_config_flavour" {
   description = "Flavour of the cluster config (secure or simple)"
   default     = "simple"
}
