#!/bin/sh
for s in $(ls ecs-compose/*.yaml)
do ./ecs-cli compose -p kube-$(basename $s .yaml) -f $s service up
done
