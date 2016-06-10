function(cfg)
  {
    "kube-proxy.json": (import "kube-proxy-ds.jsonnet")(cfg),
  }
