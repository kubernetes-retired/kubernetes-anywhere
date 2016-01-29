resource "aws_iam_instance_profile" "kubernetes-master" {
    name  = "kubernetes-master"
    path  = "/"
    roles = ["kubernetes-master"]
}

resource "aws_iam_instance_profile" "kubernetes-minion" {
    name  = "kubernetes-minion"
    path  = "/"
    roles = ["kubernetes-minion"]
}

