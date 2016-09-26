local cfg = import "../../.config.json";
{
  ["vSphere-%(cluster_name)s.tf" % cfg.phase1]: (import "vSphere.jsonnet")(cfg),
}
