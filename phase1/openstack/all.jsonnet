function(cfg)
{
  ["openstack-%(cluster_name)s.tf" % cfg.phase1]: (import "openstack.jsonnet")(cfg),
}
