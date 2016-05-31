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

output "kubernetes-master-ip" {
    value = "${aws_instance.kubernetes-master.public_ip}"
}
