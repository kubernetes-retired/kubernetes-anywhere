module "ubuntu_ami" {
    source       = "github.com/errordeveloper/tf_aws_ubuntu_ami"
    region       = "${var.aws_region}"
    distribution = "xenial"
    architecture = "amd64"
    virttype     = "hvm"
    storagetype  = "ebs-ssd"
}
