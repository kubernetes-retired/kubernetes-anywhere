FROM temp/hyperkube
LABEL io.k8s/KubernetesAnywhere/role=controller-manager

ADD controller-manager-anywhere.sh /controller-manager-anywhere
CMD [ "/controller-manager-anywhere" ]
