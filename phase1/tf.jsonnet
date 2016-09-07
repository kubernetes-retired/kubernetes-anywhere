{
  pki:: {
    local pki = self,

    private_key: {
      algorithm: "RSA",
      rsa_bits: 2048,
    },
    tls_cert_request(name, dns_names=[], ip_addresses=[]): {
      key_algorithm: "${tls_private_key.%s.algorithm}" % name,
      private_key_pem: "${tls_private_key.%s.private_key_pem}" % name,
      dns_names: dns_names,
      ip_addresses: ip_addresses,
      subject: {
        common_name: "%s_certificate" % name,
        organization: "kubernetes-anywhere",
      },
    },
    tls_self_signed_cert(name): {
      key_algorithm: "${tls_private_key.%s.algorithm}" % name,
      private_key_pem: "${tls_private_key.%s.private_key_pem}" % name,
      subject: {
        common_name: "%s_certificate" % name,
        organization: "kubernetes-anywhere",
      },
      is_ca_certificate: true,
      validity_period_hours: 365 * 24,
      allowed_uses: [
        "key_encipherment",
        "digital_signature",
        "cert_signing",
      ],
    },
    tls_locally_signed_cert(name, signer): {
      cert_request_pem: "${data.tls_cert_request.%s.cert_request_pem}" % name,
      ca_key_algorithm: "${tls_private_key.%s.algorithm}" % signer,
      ca_private_key_pem: "${tls_private_key.%s.private_key_pem}" % signer,
      ca_cert_pem: "${tls_self_signed_cert.%s.cert_pem}" % signer,
      validity_period_hours: 365 * 24,
      allowed_uses: [
        "digital_signature",
        "server_auth",
        "client_auth",
      ],
    },
    kubeconfig_from_certs(user, cluster, context, signer, apiserver_url): {
      apiVersion: "v1",
      kind: "Config",
      users: [{
        name: user,
        user: {
          "client-key-data": "${base64encode(tls_private_key.%s.private_key_pem)}" % user,
          "client-certificate-data": "${base64encode(tls_locally_signed_cert.%s.cert_pem)}" % user,
        },
      }],
      clusters: [{
        name: cluster,
        cluster: {
          "certificate-authority-data": "${base64encode(tls_self_signed_cert.%s.cert_pem)}" % signer,
          server: apiserver_url,
        },
      }],
      contexts: [{
        context: {
          cluster: cluster,
          user: user,
        },
        name: context,
      }],
      "current-context": context,
    },

    // This is a sane default pki resource. This can be used for multi-master
    // clusters or even multiple clusters but changing the list of master names or
    // ip addresses will cause all certs to be recreated tainting clusters using the
    // old certificates (i.e. causing those clusters to be recreated by terraform).

    cluster_tls_data(cluster_name, master_instance_names, master_instance_ips):: {
      tls_cert_request: {
        [cluster_name + "-" + name]: pki.tls_cert_request(cluster_name + "-" + name)
        for name in ["node", "admin"]
      } {
        [cluster_name + "-master"]: pki.tls_cert_request(
          cluster_name + "-master",
          dns_names=master_instance_names + [
            # master service dns names
            "kubernetes",
            "kubernetes.default",
            "kubernetes.default.svc",
            "kubernetes.default.svc.local",
            "kubernetes.default.svc.local",
          ],
          ip_addresses=master_instance_ips + [
            # master service ip, this depends on the cluster cidr
            # so must be changed if/when we allow that to be configured
            "10.0.0.1",
          ],
        ),
      },
    },

    cluster_tls_resources(cluster_name, master_instance_names, master_instance_ips):: {
      tls_private_key: {
        [cluster_name + "-" + name]: pki.private_key
        for name in ["root", "node", "master", "admin"]
      },
      tls_self_signed_cert: {
        [cluster_name + "-root"]: pki.tls_self_signed_cert(cluster_name + "-root"),
      },
      tls_locally_signed_cert: {
        [cluster_name + "-" + name]: pki.tls_locally_signed_cert(cluster_name + "-" + name, cluster_name + "-root")
        for name in ["node", "master", "admin"]
      },
    },

    cluster_tls(cluster_name, master_instance_names, master_instance_ips):: {
      data: pki.cluster_tls_data(cluster_name, master_instance_names, master_instance_ips),
      resource: pki.cluster_tls_resources(cluster_name, master_instance_names, master_instance_ips),
    },
  },
}
