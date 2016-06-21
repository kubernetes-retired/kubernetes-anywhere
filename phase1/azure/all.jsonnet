local cfg = import "../../.config.json";
{
  ["azure-%(instance_prefix)s.tf" % cfg.phase1]: (import "azure.jsonnet")(cfg),
}
