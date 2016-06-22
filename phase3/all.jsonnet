function(cfg)
  local if_enabled(addon, manifest) = if cfg.phase3[addon] then manifest else {};
  local join(arr) = std.foldl(function(a, b) a + b, arr, {});
  if_enabled("run_addons",
             join([
               if_enabled("kube_proxy", (import "kube-proxy/kube-proxy.jsonnet")(cfg)),
               if_enabled("dashboard", (import "dashboard/dashboard.jsonnet")(cfg)),
               if_enabled("heapster", (import "heapster/heapster.jsonnet")(cfg)),
               if_enabled("kube_dns", (import "kube-dns/kube-dns.jsonnet")(cfg)),
             ]))
