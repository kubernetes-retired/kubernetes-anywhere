module "ubuntu_ami" {
    source       = "github.com/terraform-community-modules/tf_aws_ubuntu_ami"
    region       = "${var.aws_region}"
    distribution = "willy"
    architecture = "amd64"
    virttype     = "hvm"
    storagetype  = "ssd"
}
