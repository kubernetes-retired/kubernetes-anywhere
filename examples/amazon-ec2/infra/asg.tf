resource "aws_autoscaling_group" "kubernetes-minion-group" {
    desired_capacity          = 4
    health_check_grace_period = 0
    health_check_type         = "EC2"
    launch_configuration      = "kubernetes-minion-group"
    max_size                  = 4
    min_size                  = 4
    name                      = "kubernetes-minion-group"
    vpc_zone_identifier       = ["subnet-ed556b9a"]

    tag {
        key   = "KubernetesCluster"
        value = "kubernetes"
        propagate_at_launch = true
        key   = "Name"
        value = "kubernetes-minion"
        propagate_at_launch = true
        key   = "Role"
        value = "kubernetes-minion"
        propagate_at_launch = true
    }
}

