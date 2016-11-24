mkdir -p /srv/kubernetes

vm_ip=$(ip addr | grep' "'"'state UP'"'" '-A2 | tail -n1 | awk' "'"'{print $2}'"'" '| cut -f1  -d'"'"/"'"')

cat << EOF > "/etc/default/flannel"
NETWORK=${flannel_net}
ETCD_ENDPOINTS=http://${master_ip}:4000
IFace=$vm_ip
EOF


if [ "${role}" == "master" ]; then
    # Download & Start etcd
    systemctl enable etcd
    systemctl start etcd
    # Start flannel
    systemctl enable flanneld
    systemctl start flanneld
    # Create certificates on master
    echo -n "${root_ca_public_pem}" | base64 -d > "/srv/kubernetes/ca.pem"
    echo -n "${apiserver_cert_pem}" | base64 -d > "/srv/kubernetes/apiserver.pem"
    echo -n "${apiserver_key_pem}" | base64 -d > "/srv/kubernetes/apiserver-key.pem"
    # Create kubernetes configuration 
    cat << EOF > "/srv/kubernetes/kubeconfig.json"
    ${master_kubeconfig}
EOF
else
    systemctl enable flannelc
    systemctl start flannelc    
    cat << EOF > "/srv/kubernetes/kubeconfig.json"
    ${node_kubeconfig}
EOF
fi

# Add dns entries to /etc/hosts 
echo "${nodes_dns_mappings}" >> /etc/hosts


systemctl enable docker
systemctl start docker
docker run \
  --net=host \
  -v /:/mnt/root \
  -v /run:/run \
  -v /etc/kubernetes:/etc/kubernetes \
  -v /var/lib/ignition:/usr/share/oem \
  "${installer_container}" /bin/do_role
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet

if [ "${role}" == "master" ]; then
    # Download kubectl
    curl -o /bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${kubernetes_version}/bin/linux/amd64/kubectl
    chmod 777 /bin/kubectl
fi