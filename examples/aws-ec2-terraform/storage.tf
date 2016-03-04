#resource "aws_efs_file_system" "kubernetes-efs" {
#    reference_name = "kubernetes-efs"
#
#    tags {
#        "KubernetesCluster" = "kubernetes-${var.cluster}"
#        "Name"              = "kubernetes-efs"
#    }
#}
#
#resource "aws_efs_mount_target" "kubernetes-efs" {
#    file_system_id  = "${aws_efs_file_system.kubernetes-efs.id}"
#    subnet_id       = "${aws_subnet.kubernetes-subnet.id}"
#    security_groups = [
#        "${aws_security_group.kubernetes-master.id}",
#        "${aws_security_group.kubernetes-node.id}",
#    ]
#}
