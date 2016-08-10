function(cfg)
  if cfg.role == "master" then
    (import "master.jsonnet")(cfg)
  else if cfg.role == "node" then
    (import "node.jsonnet")(cfg)
  else
    error ("need to specify role in cfg")
