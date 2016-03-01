output "kubernetes-vpc-id" {
    value = "${aws_vpc.kubernetes-vpc.id}"
}

output "kubernetes-subnet-id" {
    value = "${aws_subnet.kubernetes-subnet.id}"
}

output "kubernetes-main-sg-id" {
    value = "${aws_security_group.kubernetes-main-sg.id}"
}

output "kubernetes-master-secure-config-repository" {
    value = "${aws_ecr_repository.kubernetes-master-secure-config-repository.registry_id}/${aws_ecr_repository.kubernetes-master-secure-config-repository.name}"
}

output "kubernetes-node-secure-config-repository" {
    value = "${aws_ecr_repository.kubernetes-node-secure-config-repository.registry_id}/${aws_ecr_repository.kubernetes-node-secure-config-repository.name}"
}
