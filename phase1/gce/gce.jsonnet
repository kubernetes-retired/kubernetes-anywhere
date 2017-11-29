function(cfg)
  local tf = import "phase1/tf.jsonnet";
  local p1 = cfg.phase1;
  local p2 = cfg.phase2;
  local p3 = cfg.phase3;
  local gce = p1.gce;
  local names = {
    instance_template: "%(cluster_name)s-node-instance-template" % p1,
    instance_group: "%(cluster_name)s-node-group" % p1,
    master_instance: "%(cluster_name)s-master" % p1,
    master_ip: "%(cluster_name)s-master-ip" % p1,
    ssh_all: "%(cluster_name)s-ssh-all" % p1,
    master_external_firewall_rule: "%(cluster_name)s-master-https" % p1,
    master_internal_firewall_rule: "%(cluster_name)s-master-internal" % p1,
    node_firewall_rule: "%(cluster_name)s-node-all" % p1,
    release_bucket: "%s-kube-deploy-%s" % [gce.project, p1.cluster_name],
  };
  local instance_defaults = {
    machine_type: gce.instance_type,
    can_ip_forward: true,
    scheduling: {
      automatic_restart: true,
      on_host_maintenance: "MIGRATE",
    },
    network_interface: [{
      network: gce.network,
      access_config: {},
    }],
  };
  local startup_config = {
    startup_script:
      std.escapeStringDollars(importstr "configure-vm.sh") + (
      if p2.provider == "ignition" then
        std.escapeStringDollars(importstr "../../phase2/ignition/configure-vm-ignition.sh")
      else if p2.provider == "kubeadm" then
        std.escapeStringDollars(importstr "../../phase2/kubeadm/configure-vm-kubeadm.sh")
      else
        error "Unsupported phase2 provider in config"
    ),
    master_startup_script:
      self.startup_script + (
      if p2.provider == "kubeadm" then
        std.escapeStringDollars(importstr "../../phase2/kubeadm/configure-vm-kubeadm-master.sh")
    ),
    node_startup_script:
      self.startup_script + (
      if p2.provider == "kubeadm" then
        std.escapeStringDollars(importstr "../../phase2/kubeadm/configure-vm-kubeadm-node.sh")
    ),
  };
  local config_metadata_template = std.toString(cfg {
    master_ip: "${google_compute_address.%s.address}",
    role: "%s",
    phase3+: {
      addons_config: (import "phase3/all.jsonnet")(cfg),
    },
  });
  local kubeconfig(user, cluster, context) =
    std.manifestJson(
      tf.pki.kubeconfig_from_certs(
        user, cluster, context,
        p1.cluster_name + "-root",
        "https://${google_compute_address.%(master_ip)s.address}" % names
    ));
  {
    variable: {
      "kubeadm_token": {},
    },
    output: {
      [names.master_ip]: {
        value: "${google_compute_address.%(master_ip)s.address}" % names,
      },
    },
    provider: {
      google: {
        credentials: "${file(\"account.json\")}",
        project: gce.project,
        region: gce.region,
      },
    },
    resource: {
      google_compute_address: {
        [names.master_ip]: {
          name: names.master_ip,
          region: gce.region,
        },
      },
      google_compute_firewall: {
        [names.ssh_all]: {
          name: "%(cluster_name)s-ssh-all" % p1,
          network: gce.network,
          allow: [{
            protocol: "tcp",
            ports: ["22"],
          }],
          source_ranges: ["0.0.0.0/0"],
        },
        [names.master_external_firewall_rule]: {
          name: names.master_external_firewall_rule,
          network: gce.network,
          allow: [{
            protocol: "tcp",
            ports: ["443"],
          }],
          source_ranges: ["0.0.0.0/0"],
          target_tags: ["%(cluster_name)s-master" % p1],
        },
        [names.master_internal_firewall_rule]: {
          name: names.master_internal_firewall_rule,
          network: gce.network,
          allow: [{
            protocol: "tcp",
            ports: ["9898"],
          }],
          source_ranges: [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16",
          ],
          target_tags: ["%(cluster_name)s-master" % p1],
        },
        [names.node_firewall_rule]: {
          name: names.node_firewall_rule,
          network: gce.network,
          allow: [
            { protocol: "tcp" },
            { protocol: "udp" },
            { protocol: "icmp" },
            { protocol: "ah" },
            { protocol: "sctp" },
          ],
          source_ranges: [
            "10.0.0.0/8",
            "172.16.0.0/12",
            "192.168.0.0/16",
          ],
          target_tags: ["%(cluster_name)s-node" % p1],
        },
      },
      google_compute_instance: {
        [names.master_instance]: instance_defaults {
          name: names.master_instance,
          zone: gce.zone,
          tags: [
            "%(cluster_name)s-master" % p1,
            "%(cluster_name)s-node" % p1,
          ],
          network_interface: [{
            network: gce.network,
            access_config: {
              nat_ip: "${google_compute_address.%(master_ip)s.address}" % names,
            },
          }],
          metadata_startup_script: startup_config.master_startup_script,
          metadata: {
            "k8s-kubeadm-advertise-addresses": "${google_compute_address.%(master_ip)s.address}" % names,
            "k8s-kubeadm-cni-plugin": if std.objectHas(p3, "cni") then p3.cni else "",
          } + if p2.provider == "kubeadm" then {
            "k8s-kubeadm-token": "${var.kubeadm_token}",
            "k8s-kubeproxy-mode": if std.objectHas(p2, "proxy_mode") then "%(proxy_mode)s" % p2 else "",
            "k8s-kubeadm-version": "%(version)s" % p2.kubeadm,
            "k8s-kubeadm-kubernetes-version": "%(kubernetes_version)s" % p2,
            "k8s-kubeadm-kubelet-version": "%(kubelet_version)s" % p2,
            "k8s-kubeadm-enable-cloud-provider": (if std.objectHas(p2, "enable_cloud_provider") && p2.enable_cloud_provider then "true" else "false"),
            "k8s-kubeadm-feature-gates": if std.objectHas(p2.kubeadm, "feature_gates") then "%(feature_gates)s" % p2.kubeadm else "",
          } else {
            "k8s-config": config_metadata_template % [names.master_ip, "master"],
            "k8s-ca-public-key": "${tls_self_signed_cert.%s-root.cert_pem}" % p1.cluster_name,
            "k8s-apisever-public-key": "${tls_locally_signed_cert.%s-master.cert_pem}" % p1.cluster_name,
            "k8s-apisever-private-key": "${tls_private_key.%s-master.private_key_pem}" % p1.cluster_name,
            "k8s-master-kubeconfig": kubeconfig(p1.cluster_name + "-master", "local", "service-account-context"),
          },
          disk: [{
            image: gce.os_image,
          }],
          service_account: [
            { scopes: ["compute-rw", "storage-ro"] },
          ],
        },
      },
      google_compute_instance_template: {
        [names.instance_template]: instance_defaults {
          name: names.instance_template,
          tags: ["%(cluster_name)s-node" % p1],
          metadata: {
            "startup-script": startup_config.node_startup_script,
            "k8s-kubeadm-master-ip": "${google_compute_instance.%(master_instance)s.network_interface.0.address}" % names,
          } + if p2.provider == "kubeadm" then {
            "k8s-kubeadm-token": "${var.kubeadm_token}",
            "k8s-kubeadm-version": "%(version)s" % p2.kubeadm,
            "k8s-kubeadm-kubernetes-version": "%(kubernetes_version)s" % p2,
            "k8s-kubeadm-kubelet-version": "%(kubelet_version)s" % p2,
            "k8s-kubeadm-enable-cloud-provider": (if std.objectHas(p2, "enable_cloud_provider") && p2.enable_cloud_provider then "true" else "false"),
          } else {
            "k8s-deploy-bucket": names.release_bucket,
            "k8s-config": config_metadata_template % [names.master_ip, "node"],
            "k8s-node-kubeconfig": kubeconfig(p1.cluster_name + "-node", "local", "service-account-context"),
          },
          disk: [{
            source_image: gce.os_image,
            auto_delete: true,
            boot: true,
          }],
          service_account: [
            { scopes: ["compute-rw", "storage-ro", "https://www.googleapis.com/auth/ndev.clouddns.readwrite"] },
          ],
        },
      },
      google_compute_instance_group_manager: {
        [names.instance_group]: {
          name: names.instance_group,
          instance_template: "${google_compute_instance_template.%(instance_template)s.self_link}" % names,
          update_strategy: "NONE",
          base_instance_name: "%(cluster_name)s-node" % p1,
          zone: gce.zone,
          target_size: p1.num_nodes,
        },
      },
    } + if p2.provider != "kubeadm" then {
      // Public Key Infrastructure
      null_resource: {
        kubeconfig: {
          provisioner: [{
            "local-exec": {
              command: "echo '%s' > clusters/%s/kubeconfig.json" % [ kubeconfig(p1.cluster_name + "-admin", p1.cluster_name, p1.cluster_name), p1.cluster_name ],
            },
          }],
        },
      },
    } + tf.pki.cluster_tls_resources(p1.cluster_name, [names.master_instance], ["${google_compute_address.%(master_ip)s.address}" % names])
    else { },
  }
