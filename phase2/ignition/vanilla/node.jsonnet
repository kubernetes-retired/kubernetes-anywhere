function(cfg)
  {
    local phase1 = cfg.phase1,
    local phase2 = cfg.phase2,
    local util = import "util.jsonnet",
    ignition: { version: "2.0.0" },
    systemd: {
      units: [{
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
              "--pod-manifest-path=/etc/kubernetes/manifests",
              "--cluster-dns=10.0.0.10",
              "--cluster-domain=cluster.local",
              "--v=2",
            ],
            if cfg.role == "node" && phase1.cloud_provider != "vsphere" then
              [
                "--network-plugin=kubenet",
                "--reconcile-cidr",                
              ],            
            if cfg.role == "node" then
              [
                "--api-servers=https://" + cfg.master_ip,
                "--hairpin-mode=promiscuous-bridge",
              ]
            else
              [
                "--api-servers=http://localhost:8080",
                "--register-schedulable=false",
              ],
            if phase1.cloud_provider == "vsphere" then
              [
                "--cloud-config=/etc/kubernetes/vsphere.conf"
              ],             
          ])),
        },
      }],
    },
  }
