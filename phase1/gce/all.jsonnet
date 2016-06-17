local cfg = import "../../.config.json";
{
  ["gce-%(instance_prefix)s.tf" % cfg.phase1]: (import "gce.jsonnet")(cfg),
}
