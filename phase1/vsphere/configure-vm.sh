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
    if [ $? -ne 0 ] || [ "`systemctl is-enabled etcd`" != "enabled" ] ; then
        echo "Failed to enable etcd service"
        exit 1
    fi
    systemctl start etcd
    if [ $? -ne 0 ] || [ "`systemctl is-active etcd`" != "active" ] ; then
        echo "Failed to start etcd service"
        exit 1
    fi
    # Start flannel
    systemctl enable flanneld
    if [ $? -ne 0 ] || [ "`systemctl is-enabled flanneld`" != "enabled" ] ; then
        echo "Failed to enable flanneld"
        exit 1
    fi
    systemctl start flanneld
    if [ $? -ne 0 ] || [ "`systemctl is-active flanneld`" != "active" ] ; then
        echo "Failed to start flanneld"
        exit 1
    fi
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
    if [ $? -ne 0 ] || [ "`systemctl is-enabled flannelc`" != "enabled" ] ; then
        echo "Failed to enable flannelc"
        exit 1
    fi
    systemctl start flannelc    
    if [ $? -ne 0 ] || [ "`systemctl is-active flannelc`" != "active" ] ; then
        echo "Failed to start flannelc"
        exit 1
    fi
    cat << EOF > "/srv/kubernetes/kubeconfig.json"
    ${node_kubeconfig}
EOF
fi

# Add dns entries to /etc/hosts 
echo "${nodes_dns_mappings}" >> /etc/hosts


systemctl enable docker
if [ $? -ne 0 ] || [ "`systemctl is-enabled docker`" != "enabled" ] ; then
    echo "Failed to enable docker"
    exit 1
fi
systemctl start docker
if [ $? -ne 0 ] || [ "`systemctl is-active docker`" != "active" ] ; then
    echo "Failed to start docker"
    exit 1
fi

docker pull \
  ${docker_registry}/hyperkube-amd64:${kubernetes_version}
if [ $? -ne 0 ]; then
    echo "Failed to docker pull hyperkube"
    exit 1
fi

docker run \
  --net=host \
  -v /:/mnt/root \
  -v /run:/run \
  -v /etc/kubernetes:/etc/kubernetes \
  -v /var/lib/ignition:/usr/share/oem \
  "${installer_container}" /bin/do_role
if [ $? -ne 0 ]; then
    echo "Failed to docker run installer container"
    exit 1
fi

systemctl daemon-reload
if [ $? -ne 0 ]; then
    echo "Failed to reload daemon"
    exit 1
fi
systemctl enable kubelet
if [ $? -ne 0 ] || [ "`systemctl is-enabled kubelet`" != "enabled" ] ; then
    echo "Failed to enable kubelet"
    exit 1
fi
systemctl start kubelet
if [ $? -ne 0 ] || [ "`systemctl is-active kubelet`" != "active" ] ; then
    echo "Failed to start kubelet"
    exit 1
fi
