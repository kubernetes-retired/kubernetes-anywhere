# Copyright 2015-2016 Weaveworks Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
