output "kubernetes-vpc-id" {
    value = "${aws_vpc.kubernetes-vpc.id}"
}

output "kubernetes-subnet-id" {
    value = "${aws_subnet.kubernetes-subnet.id}"
}

output "kubernetes-main-sg-id" {
    value = "${aws_security_group.kubernetes-main-sg.id}"
}

output "kubernetes-master-pki-repository" {
    value = "${aws_ecr_repository.kubernetes-master-pki-repository.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.kubernetes-master-pki-repository.name}"
}

output "kubernetes-node-pki-repository" {
    value = "${aws_ecr_repository.kubernetes-node-pki-repository.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.kubernetes-node-pki-repository.name}"
}
