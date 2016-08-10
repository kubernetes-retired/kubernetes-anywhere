function(cfg)
  local util = import "util.jsonnet";
  {
    apiVersion: "v1",
    kind: "Pod",
    metadata: {
      name: "kube-controller-manager",
      namespace: "kube-system",
      labels: {
        tier: "control-plane",
        component: "kube-controller-manager",
      },
    },
    spec: {
      hostNetwork: true,
      containers: [
        {
          name: "kube-controller-manager",
          image: "%(docker_registry)s/hyperkube-amd64:%(kubernetes_version)s" % cfg.phase2,
          resources: {
            requests: {
              cpu: "200m",
            },
          },
          command: util.build_params([
            [
              "/hyperkube",
              "controller-manager",
              "--master=127.0.0.1:8080",
              "--cluster-name=" + cfg.phase1.cluster_name,
              "--cluster-cidr=10.244.0.0/16",
              "--allocate-node-cidrs=true",
              "--cloud-provider=%s" % cfg.phase1.cloud_provider,
              "--service-account-private-key-file=/srv/kubernetes/apiserver-key.pem",
              "--root-ca-file=/srv/kubernetes/ca.pem",
              "--v=2",
            ],
            if cfg.phase1.cloud_provider == "azure" then
              ["--cloud-config=/etc/kubernetes/azure.json"],
          ]),
          livenessProbe: {
            httpGet: {
              host: "127.0.0.1",
              port: 10252,
              path: "/healthz",
            },
            initialDelaySeconds: 15,
            timeoutSeconds: 15,
          },
          volumeMounts: [
            {
              name: "srvkube",
              mountPath: "/srv/kubernetes",
              readOnly: true,
            },
            {
              name: "etckube",
              mountPath: "/etc/kubernetes",
              readOnly: true,
            },
            {
              name: "etcssl",
              mountPath: "/etc/ssl",
              readOnly: true,
            },
          ],
        },
      ],
      volumes: [
        {
          name: "srvkube",
          hostPath: {
            path: "/srv/kubernetes",
          },
        },
        {
          name: "etckube",
          hostPath: {
            path: "/etc/kubernetes",
          },
        },
        {
          name: "etcssl",
          hostPath: {
            path: "/etc/ssl",
          },
        },
      ],
    },
  }
