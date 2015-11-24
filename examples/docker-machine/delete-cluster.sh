#!/bin/bash
docker-machine rm -f `seq -f 'kube-%g' 1 7`
