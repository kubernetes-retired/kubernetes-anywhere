function(cfg)
{
  ["gce-%(cluster_name)s.tf" % cfg.phase1]: (import "gce.jsonnet")(cfg),
}
