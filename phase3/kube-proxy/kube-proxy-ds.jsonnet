function(cfg)
  {
    kind: "DaemonSet",
    apiVersion: "extensions/v1beta1",
    metadata: {
      labels: {
        tier: "node",
        component: "kube-proxy",
      },
      namespace: "kube-system",
      name: "kube-proxy",
    },
    spec: {
      template: {
        metadata: {
          labels: {
            tier: "node",
            component: "kube-proxy",
          },
        },
        spec: {
          hostNetwork: true,
          containers: [
            {
              securityContext: {
                privileged: true,
              },
              name: "kube-proxy",
              command: [
                  "/hyperkube",
                  "proxy",
                  "--kubeconfig=/srv/kubernetes/kubeconfig.json",
                  "--resource-container=\"\"",
              ],
              image: "%(docker_registry)s/hyperkube-amd64:%(kubernetes_version)s" % cfg.phase2,
              volumeMounts: [
                {
                  readOnly: true,
                  mountPath: "/etc/ssl/certs",
                  name: "ssl-certs-host",
                },
                {
                  readOnly: false,
                  mountPath: "/srv/kubernetes/kubeconfig.json",
                  name: "kubeconfig",
                },
              ],
              resources: {
                requests: {
                  cpu: "100m",
                },
              },
            },
          ],
          volumes: [
            {
              hostPath: {
                path: "/usr/share/ca-certificates",
              },
              name: "ssl-certs-host",
            },
            {
              hostPath: {
                path: "/srv/kubernetes/kubeconfig.json",
              },
              name: "kubeconfig",
            },
          ],
        },
      },
    },
  }
