{
  pki:: {
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
      cert_request_pem: "${tls_cert_request.%s.cert_request_pem}" % name,
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
    kubeconfig_from_certs(name, signer, apiserver_url): {
      apiVersion: "v1",
      kind: "Config",
      users: [{
        name: name,
        user: {
          "client-key-data": "${base64encode(tls_private_key.%s.private_key_pem)}" % name,
          "client-certificate-data": "${base64encode(tls_locally_signed_cert.%s.cert_pem)}" % name,
        },
      }],
      clusters: [{
        name: "local",
        cluster: {
          "certificate-authority-data": "${base64encode(tls_self_signed_cert.%s.cert_pem)}" % signer,
          server: apiserver_url,
        },
      }],
      contexts: [{
        context: {
          cluster: "local",
          user: name,
        },
        name: "service-account-context",
      }],
      "current-context": "service-account-context",
    },
  },
}
