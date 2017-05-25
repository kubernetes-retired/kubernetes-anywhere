function(cfg)
  local if_enabled(addon, manifest) = if std.objectHas(cfg, "phase3") && std.objectHas(cfg.phase3, addon) && cfg.phase3[addon] then manifest else {};
  local if_cni_plugin(plugin, manifest) = if std.objectHas(cfg.phase3, "cni") && cfg.phase3["cni"] == plugin then manifest else {};
  local join(arr) = std.foldl(function(a, b) a + b, arr, {});
  if_enabled("run_addons",
             join([
               if_enabled("kube_proxy", (import "kube-proxy/kube-proxy.jsonnet")(cfg)),
               if_enabled("dashboard", (import "dashboard/dashboard.jsonnet")(cfg)),
               if_enabled("heapster", (import "heapster/heapster.jsonnet")(cfg)),
               if_enabled("kube_dns", (import "kube-dns/kube-dns.jsonnet")(cfg)),
               if_enabled("weave_net", (import "weave-net/weave-net.jsonnet")(cfg)),
               if_cni_plugin("weave", (import "weave-net/weave-net.jsonnet")(cfg)),
               if_cni_plugin("flannel", (import "flannel/flannel.jsonnet")(cfg)),
               if_cni_plugin("calico", (import "calico/calico.jsonnet")(cfg)),
               if_enabled("gce_storage_class", (import "gce-storage-class/storage-class.jsonnet")(cfg)),
             ]))
