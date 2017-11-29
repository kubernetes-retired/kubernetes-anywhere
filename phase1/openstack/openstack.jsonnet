function(cfg)
  local tf = import "phase1/tf.jsonnet";
  local p1 = cfg.phase1;
  local p2 = cfg.phase2;
  local p3 = cfg.phase3;
  local openstack = p1.openstack;
  local names = {
    node_instance: "%(cluster_name)s_node" % p1,
    master_instance: "%(cluster_name)s_master" % p1,
    master_ip: "%(cluster_name)s_master_ip" % p1,
    security_group: "%(cluster_name)s_secgroup" % p1,
    key_pair: "%(cluster_name)s_key_pair" % p1,
  };
  local instance_defaults = {
    flavor_name: openstack.flavor_name,
    image_name: openstack.os_image,
    config_drive: true,
    network: {
      name: openstack.network_name,
    },
  };
  local startup_config = {
    startup_script:
      std.escapeStringDollars(importstr "configure-vm.sh") + (
      if p2.provider == "kubeadm" then
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

  {
    variable: {
      "kubeadm_token": {},
    },

    output: {
      [names.master_ip]: {
        value: "${openstack_compute_floatingip_v2.%(master_ip)s.address}" % names,
      },
    },

    provider: {
      openstack: {
        user_name: openstack.username,
        tenant_name: openstack.project_name,
        domain_name: openstack.domain_name,
        password: openstack.password,
        auth_url: openstack.auth_url,
      },
    },

    data: {
      local common_vars = {
        k8s_kubeadm_version: "%(version)s" % p2.kubeadm,
        k8s_kubeadm_kubernetes_version: "%(kubernetes_version)s" % p2,
        k8s_kubeadm_advertise_addresses: "${openstack_compute_floatingip_v2.%(master_ip)s.address}" % names,
        k8s_kubeadm_token: "${var.kubeadm_token}",
        k8s_kubeproxy_mode: "%(proxy_mode)s" % p2,
        k8s_kubeadm_cni_plugin: if std.objectHas(p3, "cni") then p3.cni else "",
        k8s_kubeadm_kubelet_version: "%(kubelet_version)s" % p2,
        k8s_kubeadm_enable_cloud_provider: (if std.objectHas(p2, "enable_cloud_provider") && p2.enable_cloud_provider then "true" else "false"),
        k8s_kubeadm_master_ip: "",
        k8s_kubeadm_feature_gates: if std.objectHas(p2.kubeadm, "feature_gates") then "%(feature_gates)s" % p2.kubeadm else "",
      },
      "template_file": {
        "master": {
          template: startup_config.master_startup_script,
          vars: common_vars,
        },
        "node": {
          template: startup_config.node_startup_script,
          vars: common_vars {
            k8s_kubeadm_master_ip: "${openstack_compute_instance_v2.%(master_instance)s.network.0.fixed_ip_v4}" % names,
          },
        },
      },
    },

    resource: {
      openstack_compute_keypair_v2: {
        [names.key_pair]: {
          name: names.key_pair,
          public_key: "${file(\"%s.pub\")}" % openstack.ssh_key_file,
        },
      },
      openstack_compute_secgroup_v2: {
        [names.security_group]: {
          name: names.security_group,
          description: "Security Group for k8s cluster %(cluster_name)s" % p1,
          rule: [{
            ip_protocol: "tcp",
            from_port: "22",
            to_port: "22",
            cidr: "0.0.0.0/0",
          },
          {
            ip_protocol: "tcp",
            from_port: "443",
            to_port: "443",
            cidr: "0.0.0.0/0",
          },
          {
            ip_protocol: "icmp",
            from_port: "-1",
            to_port: "-1",
            cidr: "0.0.0.0/0",
          },
          {
            ip_protocol: "tcp",
            from_port: "1",
            to_port: "65535",
            "self": true,
          },
          {
            ip_protocol: "udp",
            from_port: "1",
            to_port: "65535",
            "self": true,
          },
          {
            ip_protocol: "icmp",
            from_port: "-1",
            to_port: "-1",
            "self": true,
          }],
        },
      },
      openstack_compute_floatingip_v2: {
        [names.master_ip]: {
          pool: openstack.floatingip_pool_name,
        },
      },
      openstack_compute_floatingip_associate_v2: {
       "instance_floating": {
          floating_ip: "${openstack_compute_floatingip_v2.%(master_ip)s.address}" % names,
          instance_id: "${openstack_compute_instance_v2.%(master_instance)s.id}" % names,
        },
      },
      openstack_networking_network_v2: {
        [openstack.network_name]: {
          name: openstack.network_name,
          admin_state_up: "true",
        },
      },
      openstack_networking_subnet_v2: {
        [openstack.network_name]: {
          name: openstack.network_name,
          network_id: "${openstack_networking_network_v2.%s.id}" % openstack.network_name,
          cidr: openstack.network_cidr,
          ip_version: 4,
        },
      },
      openstack_networking_router_v2: {
        [openstack.network_name]: {
          name: openstack.network_name,
          admin_state_up: "true",
          external_gateway: openstack.external_gateway,
        },
      },
      openstack_networking_router_interface_v2: {
        [openstack.network_name]: {
          router_id: "${openstack_networking_router_v2.%s.id}" % openstack.network_name,
          subnet_id: "${openstack_networking_subnet_v2.%s.id}" % openstack.network_name,
        },
      },
      openstack_compute_instance_v2: {
        [names.master_instance]: instance_defaults {
          name: names.master_instance,
          key_pair: "${openstack_compute_keypair_v2.%s.name}" % names.key_pair,
          security_groups: [ "${openstack_compute_secgroup_v2.%s.name}" % names.security_group ],
          user_data: "${data.template_file.master.rendered}",
          depends_on: ["openstack_networking_router_interface_v2.%s" % openstack.network_name],
        },
        [names.node_instance]: instance_defaults {
          name: "%s_${count.index+1}" % names.node_instance,
          count: p1.num_nodes,
          key_pair: "${openstack_compute_keypair_v2.%s.name}" % names.key_pair,
          security_groups: [ "${openstack_compute_secgroup_v2.%s.name}" % names.security_group ],
          user_data: "${data.template_file.node.rendered}",
          depends_on: ["openstack_networking_router_interface_v2.%s" % openstack.network_name],
        },
      },
    },
  }
