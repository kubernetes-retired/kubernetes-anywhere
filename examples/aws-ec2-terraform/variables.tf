variable "cluster" {
   description = "Kubernetes cluster suffix"
   default     = "a2"
}

variable "ec2_region" {
   description = "EC2 region"
   default     = "eu-west-1"
}

variable "ami" {
   description = "AMI ID"
   type        = "map"

   default     = {
       "eu-west-1"    = "ami-36289a45"
       "eu-central-1" = "ami-30677d5c"
   }
}

variable "node_instance_type" {
   description = "EC2 instance type for worker nodes"
   default     = "m3.xlarge"
}

variable "master_instance_type" {
    description = "EC2 instance type for master node(s)"
    default     = "m3.xlarge"
}

variable "etcd_instance_type" {
    description = "EC2 instance type for etcd node(s)"
    default     = "t2.large"
}

variable "ec2_key_name" {
   description = "SSH key name to use for EC2 instances"
   default     = "kubernetes-anywhere"
}
