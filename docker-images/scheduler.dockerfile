FROM temp/hyperkube
LABEL io.k8s/KubernetesAnywhere/role=scheduler

ADD scheduler-anywhere.sh /scheduler-anywhere
CMD [ "/scheduler-anywhere" ]
