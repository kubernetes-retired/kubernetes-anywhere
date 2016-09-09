function(cfg)
  {
    local phase1 = cfg.phase1,
    local phase2 = cfg.phase2,
    local util = import "util.jsonnet",
    ignition: { version: "2.0.0" },
    systemd: {
      units: [
        if phase1.azure.use_ephemeral_drive == "yes" then
          [
            {
              name: "format-ephemeral.service",
              enable: true,
              contents: (importstr "tasks/format-ephemeral.service"),
            },
	    {
              name: "var-lib-docker.mount",
              enable: true,
              contents: (importstr "tasks/var-lib-docker.mount"),
            },
          ],
        {
          name: "kubelet.service",
          enable: true,
          contents: (importstr "kubelet.service") % {
            docker_registry: phase2.docker_registry,
            kubernetes_version: phase2.kubernetes_version,
            kubelet_args: std.join(" ", util.build_params([
              [
                "--address=0.0.0.0",
                "--allow-privileged=true",
                "--cloud-provider=" + phase1.cloud_provider,
                "--enable-server",
                "--enable-debugging-handlers",
                "--kubeconfig=/srv/kubernetes/kubeconfig.json",
                "--config=/etc/kubernetes/manifests",
                "--cluster-dns=10.0.0.10",
                "--cluster-domain=cluster.local",
                "--v=2",
              ],
              if cfg.role == "node" then
                [
                  "--api-servers=https://" + cfg.master_ip,
                  "--hairpin-mode=promiscuous-bridge",
                  "--network-plugin=kubenet",
                  "--reconcile-cidr",
                ]
              else
                [
                  "--api-servers=http://localhost:8080",
                  "--register-schedulable=false",
                ],
              if phase1.cloud_provider == "azure" then
                [
                  "--cloud-config=/etc/kubernetes/azure.json",
                ]
            ]))
          }
        }       
      ]
    }
  }
