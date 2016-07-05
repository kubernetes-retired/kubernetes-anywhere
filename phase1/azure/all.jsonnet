local cfg = import "../../.config.json";
{
  ["azure-%(cluster_name)s.tf" % cfg.phase1]: (import "azure.jsonnet")(cfg),
}
