# Kubernetes Anywhere as a Job

*Run kubernetes-anywhere with env vars*
*This has only been tested on GCE*

### Goals and Motivation

This automated version of Kubernetes Anywhere will allow you to run deploy/destroy from a script or a job. 

### Config File Creation
The Kubernetes Anywhere project utilizes Kconfig to ask the user questions. This process creates a .config file. That file is used to create .config.json and so on... As the Kconfig file tree is traversed the environment is examined for a matching variable. If found, it assigns the value and validates it. The variables in Kconfig have a phase1/2/3 prefix so we strip that off, swap all . with _ and then turn it to upper case. 
If we see the following:
```
menuconfig phase1.cloud_provider
	string "cloud provider: gce, azure or vsphere"
	default "gce"
	help
	  The cloud provider you would like to deploy to.
```
We strip off 'phase1.' and search the env for CLOUD_PROVIDER

Another example:
```
config phase1.gce.project
	string "GCP project"
	help
	  The GCP project to use.
```
We strip off the 'phase1.' and search the env for GCE_PROJECT. In this example there is no default so it will exit if not set. If the Kconfig files change, this code will ask for the new values. The job will continue to parse the files and ENV even after an error. At the end of this process it will exit if there are errors. Either way it prints all Kconfig vars it finds and whether it set a default. An error is prefixed with ERR

Example output:
```
ENV[phase1.num_nodes] NUM_NODES="2" (ok)
ENV[phase1.cluster_name] CLUSTER_NAME="dev-cluster4" (ok)
ENV[phase1.cloud_provider] CLOUD_PROVIDER="gce" (ok)
ENV[phase1.gce.os_image] GCE_OS_IMAGE="ubuntu-1604-xenial-v20160420c" (env var missing, using default)
ENV[phase1.gce.instance_type] GCE_INSTANCE_TYPE="n1-standard-2" (env var missing, using default)
ERR[phase1.gce.project] GCE_PROJECT="" (missing required env var, no default found)
<snip>
```


The result will produce a .config file. The rest of the make process is unaltered.

### Environment Variables
Common required ENV vars:

  * IS_JOB
    - can be set to any value. 
    - If set, the container will run in non-interactive mode.
  * CLUSTER_NAME
  * CLOUD_PROVIDER=[gce|azure|vsphere]

GCE required ENV vars:

  * GCE_PROJECT

Azure required ENV vars:

  * // TODO

vSphere required ENV vars:

  * // TODO

Optional ENV vars:

  * DELETE_CLUSTER | DESTROY_CLUSTER
    - can be set to any value. 
    - If set, the container will run in destroy mode.
  * KUBEADM_TOKEN
    - If set, the value will be used instead of one being generated.

### Storing the Configs
The container will exit when it completes. There are config and state files on-board that we will need later to destroy the cluster. A tar.gz file of the configs is stored in kubernetes as a secret in the kube-system namespace.

### Credentials in the Image

One shouldn't build an image with credentials baked into it. If you are running this as a kubernetes job, you can mount whatever config files you need as files. In Docker, mounting a single file in a directory doesn't work. It creates an empty directory named with the file name. No bueno! If you want, you can mount a directory called /crush and the entrypoint script will copy those files into the /opt/kubernetes-anywhere directory. You must replicate the folder structure if you want the files to end up in a particular directory. 
Example:
```
# The file...
/crush/phase1/gce/.tmp/kubecontrol.json
# will be copied to...
/opt/kubernetes-anywhere/phase1/gce/.tmp/kubecontrol.json
```
You can overwrite any file you wish using /crush. 


### Deploy

Here is an example GCE deploy using docker. 
```
# file structure of /crush, contains GCE account file
#  crush
#  └─ phase1
#     └─ gce
#        └─ account.json
```


Fully automated example:
```
docker run -it --rm --volume=`pwd`/crush:/crush \
        -e GCE_PROJECT=<your-google-project-here> \
        -e CLUSTER_NAME=chris-cluster3 \
        -e CLOUD_PROVIDER=gce \
        -e IS_JOB=y \
        kubernetes-anywhere:v0.0.1
```

Testing mode:
```
make docker-dev

export GCE_PROJECT=<your-google-project-here>
export CLUSTER_NAME=chris-cluster3 \
export CLOUD_PROVIDER=gce \
export IS_JOB=y \

# verify env vars
./util/env_to_config.py

# run it
./entrypoint.sh
```

IMPORTANT!! 
The container will exit and the kubeconfig.json file will go along with it. This file is required to connect using kubectl and also to destroy the cluster. The kubecontrol.json file is base64 encoded and then printed to STDOUT as KUBECONFIG_JSON=<base64>.
You can manually decode it like this:
```
echo <the KUBECONFIG_JSON value> | base64 -d > kubecontrol.json
```
Save the file!

### Destroy

Here is an example GCE destroy using docker. 
```
# file structure of /crush, contains the kubecontrol.json
#  crush
#  └─ phase1
#     └─ gce
#        └─ .tmp
#           └─ kubecontrol.json 
```
Fully automated example:
```
docker run -it --rm --volume=`pwd`/crush:/crush \
        -e CLOUD_PROVIDER=gce \
        -e IS_JOB=y \
        -e DESTROY_CLUSTER=y \
        kubernetes-anywhere:v0.0.1
```

Testing mode:
```
make docker-dev

export CLOUD_PROVIDER=gce
export IS_JOB=y
export DESTROY_CLUSTER=y

./entrypoint.sh
```


### TODO
Create example yaml files for kubernetes job
