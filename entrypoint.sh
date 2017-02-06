#!/bin/bash
set -o pipefail

# Check ENV to see if we run in interactive mode or ENV mode.
if [ -n "$CLOUD_PROVIDER" ];
then
	./util/env_to_config.py
	if [ $? -ne 0 ];
	then
		echo "ENV Vars are incorrect, look for ERR: in log"
		exit 1
	fi
	exec make $@
	./util/echo_configs.py
	exit
fi

exec make $@
