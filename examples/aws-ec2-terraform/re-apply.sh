#!/bin/bash

terraform taint aws_launch_configuration.kubernetes-node-group
terraform taint aws_autoscaling_group.kubernetes-node-group
terraform apply
