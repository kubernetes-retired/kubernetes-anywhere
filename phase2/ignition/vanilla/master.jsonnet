function(cfg)
  (import "node.jsonnet")(cfg) {
    local util = import "util.jsonnet",   
    local phase2 = cfg.phase2,
    local kubectl = "https://storage.googleapis.com/kubernetes-release/release/" + phase2.kubernetes_version + "/bin/linux/amd64/kubectl",
    storage: {
      filesystems: [{
        name: "root",
        path: "/mnt/root",
      }],
      files: [
        {
          filesystem: "root",
          path: "/etc/kubernetes/manifests/" + manifest.name,
          contents: { source: util.encode_data(manifest.template(cfg)) },
        }
        for manifest in [
          {
            name: "kube-apiserver.json",
            template: import "manifest/kube-apiserver.jsonnet",
          },
          {
            name: "kube-controller-manager.json",
            template: import "manifest/kube-controller-manager.jsonnet",
          },
          {
            name: "kube-scheduler.json",
            template: import "manifest/kube-scheduler.jsonnet",
          },
          {
            name: "etcd.json",
            template: import "manifest/etcd.jsonnet",
          },
        ]
      ] + [
        {
          filesystem: "root",
          path: "/usr/local/bin/kubectl",
          contents: {
            source: kubectl,
	  },
          mode: 511,
        },
      ],
    },
  }
