output "kubernetes-vpc-id" {
    value = "${aws_vpc.kubernetes-vpc.id}"
}

output "kubernetes-subnet-id" {
    value = "${aws_subnet.kubernetes-subnet.id}"
}

output "kubernetes-main-sg-id" {
    value = "${aws_security_group.kubernetes-main-sg.id}"
}
