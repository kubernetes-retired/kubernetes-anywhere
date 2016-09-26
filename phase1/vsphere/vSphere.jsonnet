function(config)
  local tf = import "phase1/tf.jsonnet";
  local cfg = config.phase1;
  local vms = std.makeArray(cfg.num_nodes + 1,function(node) node+1); 
  local master_dependency_list = ["vsphere_virtual_machine.kubedebian%d" % vm for vm in vms];
  local node_name_to_ip = [("${vsphere_virtual_machine.kubedebian%d.network_interface.0.ipv4_address} %s"  % [vm, (if vm == 1 then "master" else "node%d" % (vm-1) )])  for vm in vms];
  local vm_username = "root";
  local vm_password = "kubernetes";

  local kubeconfig(user, cluster, context) =
    std.manifestJson(
      tf.pki.kubeconfig_from_certs(
        user, cluster, context,
        cfg.cluster_name + "-root",
        "https://${vsphere_virtual_machine.kubedebian1.network_interface.0.ipv4_address}",
      ));

  local config_metadata_template = std.toString(config {
      master_ip: "${vsphere_virtual_machine.kubedebian1.network_interface.0.ipv4_address}",
      role: "%s",
      phase3 +: {
        addons_config: (import "phase3/all.jsonnet")(config),
      },
    });
  
  std.mergePatch({
    // vSphere Configuration
    provider: {
      vsphere: {
        user: cfg.vSphere.username,
        password: cfg.vSphere.password,
        vsphere_server: cfg.vSphere.url,
        allow_unverified_ssl: cfg.vSphere.insecure,
      },
    },
    
     data: {
      template_file: {
        configure_master: {
          template: "${file(\"configure-vm.sh\")}",
          vars: {
            role: "master",
            root_ca_public_pem: "${base64encode(tls_self_signed_cert.%s-root.cert_pem)}" % cfg.cluster_name,
            apiserver_cert_pem: "${base64encode(tls_locally_signed_cert.%s-master.cert_pem)}" % cfg.cluster_name,
            apiserver_key_pem: "${base64encode(tls_private_key.%s-master.private_key_pem)}" % cfg.cluster_name,
            master_kubeconfig: kubeconfig(cfg.cluster_name + "-master", "local", "service-account-context"),
            node_kubeconfig: kubeconfig(cfg.cluster_name + "-node", "local", "service-account-context"),
            master_ip: "${vsphere_virtual_machine.kubedebian1.network_interface.0.ipv4_address}",
            nodes_dns_mappings: std.join("\n", node_name_to_ip),
            flannel_net: cfg.vSphere.flannel_net,
            installer_container: config.phase2.installer_container,
            kubernetes_version: config.phase2.kubernetes_version, 
          },
        },
        configure_node: {
          template: "${file(\"configure-vm.sh\")}",
          vars: {
            role: "node",
            root_ca_public_pem: "${base64encode(tls_self_signed_cert.%s-root.cert_pem)}" % cfg.cluster_name,
            apiserver_cert_pem: "${base64encode(tls_locally_signed_cert.%s-master.cert_pem)}" % cfg.cluster_name,
            apiserver_key_pem: "${base64encode(tls_private_key.%s-master.private_key_pem)}" % cfg.cluster_name,
            master_kubeconfig: kubeconfig(cfg.cluster_name + "-master", "local", "service-account-context"),
            node_kubeconfig: kubeconfig(cfg.cluster_name + "-node", "local", "service-account-context"),
            master_ip: "${vsphere_virtual_machine.kubedebian1.network_interface.0.ipv4_address}",
            nodes_dns_mappings: std.join("\n", node_name_to_ip),
            flannel_net: cfg.vSphere.flannel_net,
            installer_container: config.phase2.installer_container,
            kubernetes_version: config.phase2.kubernetes_version,
          },
        },
        // Populates vSphere cloudprovider config file
        cloudprovider: {
          template: "${file(\"vsphere.conf\")}",
          vars: {
            username: cfg.vSphere.username,
            password: cfg.vSphere.password,
            vsphere_server: cfg.vSphere.url,
            port: cfg.vSphere.port,
            allow_unverified_ssl: cfg.vSphere.insecure,
            datacenter: cfg.vSphere.datacenter,
            datastore: cfg.vSphere.datastore,
            working_dir: cfg.cluster_name,
          },
        },
      },
     },

    
    resource: {
      "vsphere_folder":{
        "cluster_folder": {
          datacenter: cfg.vSphere.datacenter, 
          path: cfg.cluster_name,
        },
      },
      vsphere_virtual_machine: {
        ["kubedebian" + vm]: {
            name: (if vm == 1 then "master" else ("node%d" % (vm-1))),
            vcpu: cfg.vSphere.vcpu,
            memory: cfg.vSphere.memory,
            enable_disk_uuid: true,
            datacenter: cfg.vSphere.datacenter,
            skip_customization: true,
            folder: "${vsphere_folder.cluster_folder.path}",
            network_interface: {
              label: "VM Network",
            },

            disk: {
              template: cfg.vSphere.template, 
              bootable: true,
              type: "thin",
            },
        } for vm in vms
      },
      null_resource: {
        master: {
            depends_on: master_dependency_list,
            connection: {
              user: vm_username,
              password: vm_password,
              host: "${vsphere_virtual_machine.kubedebian1.network_interface.0.ipv4_address}"
            },
            provisioner: [{
                "remote-exec": {
                  inline: [
                    "mkdir -p /etc/kubernetes/; echo '%s' > /etc/kubernetes/k8s_config.json " % (config_metadata_template % "master"),                    
                    "echo '%s' > /etc/configure-vm.sh; bash /etc/configure-vm.sh" % "${data.template_file.configure_master.rendered}",
                    "echo '%s' >  /etc/kubernetes/vsphere.conf" % "${data.template_file.cloudprovider.rendered}",            
                  ]
                }
           }, {
            "local-exec": {
              command: "echo '%s' > ./.tmp/kubeconfig.json" % kubeconfig(cfg.cluster_name + "-admin", cfg.cluster_name, cfg.cluster_name),
            },
           }],
        },} + {
        ["node" + vm]: {
            depends_on: ["vsphere_virtual_machine.kubedebian1","vsphere_virtual_machine.kubedebian%d" % vm],
            connection: {
              user: vm_username,
              password: vm_password,
              host: "${vsphere_virtual_machine.kubedebian%d.network_interface.0.ipv4_address}" % vm
            },
            provisioner: [{
                "remote-exec": {
                  inline: [
                    "mkdir -p /etc/kubernetes/; echo '%s' > /etc/kubernetes/k8s_config.json " % (config_metadata_template % "node"),                    
                    "echo '%s' > /etc/configure-vm.sh; bash /etc/configure-vm.sh" % "${data.template_file.configure_node.rendered}",
                    "echo '%s' >  /etc/kubernetes/vsphere.conf" % "${data.template_file.cloudprovider.rendered}",            
                  ]
                }
           }],
        } for vm in vms if vm > 1 },
    },    
  }, tf.pki.cluster_tls(cfg.cluster_name, ["%(cluster_name)s-master" % cfg], ["${vsphere_virtual_machine.kubedebian1.network_interface.0.ipv4_address}"]))