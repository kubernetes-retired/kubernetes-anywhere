local cfg = import "../../.config.json";
{
  ["gce-%(cluster_name)s.tf" % cfg.phase1]: (import "gce.jsonnet")(cfg),
}
