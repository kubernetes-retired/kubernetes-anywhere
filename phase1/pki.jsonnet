{
  local pki = {
    private_key: {
      algorithm: "ECDSA",
      ecdsa_curve: "P384",
    },
  },
  resource: {
    tls_private_key: {
      root: pki.private_key,
      kubelet: pki.private_key,
      apiserver: pki.private_key,
      admin: pki.private_key,
    },
    tls_self_signed_cert: {
      root: {
        key_algorithm: "${tls_private_key.root.algorithm}",
        private_key_pem: "${tls_private_key.root.private_key_pem}",
        subject: {
          common_name: "root_certificate",
          organization: "kubernetes-anywhere",
        },
        validity_period_hours: 365 * 24,
        allowed_uses: [
          "key_encipherment",
          "digital_signature",
        ],
      },
    },
    tls_cert_request: {
      kubelet: {
        key_algorithm: "${tls_private_key.kubelet.algorithm}",
        private_key_pem: "${tls_private_key.kubelet.private_key_pem}",
        subject: {
          common_name: "kubelet_certificate",
          organization: "kubernetes-anywhere",
        },
      },
      apiserver: {
        key_algorithm: "${tls_private_key.apiserver.algorithm}",
        private_key_pem: "${tls_private_key.apiserver.private_key_pem}",
        subject: {
          common_name: "apiserver_certificate",
          organization: "kubernetes-anywhere",
        },
      },
      admin: {
        key_algorithm: "${tls_private_key.admin.algorithm}",
        private_key_pem: "${tls_private_key.admin.private_key_pem}",
        subject: {
          common_name: "admin_certificate",
          organization: "kubernetes-anywhere",
        },
      },
    },
    tls_locally_signed_cert: {
      kubelet_certificate: {
        cert_request_pem: "${tls_cert_request.kubelet.cert_request_pem}",
        ca_key_algorithm: "${tls_private_key.root.algorithm}",
        ca_private_key_pem: "${tls_private_key.root.private_key_pem}",
        ca_cert_pem: "${tls_self_signed_cert.root.cert_pem}",
        validity_period_hours: 365 * 24,
        allowed_uses: [
          "digital_signature",
          "server_auth",
          "client_auth",
        ],
      },
      apiserver_certificate: {
        cert_request_pem: "${tls_cert_request.apiserver.cert_request_pem}",
        ca_key_algorithm: "${tls_private_key.root.algorithm}",
        ca_private_key_pem: "${tls_private_key.root.private_key_pem}",
        ca_cert_pem: "${tls_self_signed_cert.root.cert_pem}",
        validity_period_hours: 365 * 24,
        allowed_uses: [
          "digital_signature",
          "server_auth",
          "client_auth",
        ],
      },
      admin_certificate: {
        cert_request_pem: "${tls_cert_request.admin.cert_request_pem}",
        ca_key_algorithm: "${tls_private_key.root.algorithm}",
        ca_private_key_pem: "${tls_private_key.root.private_key_pem}",
        ca_cert_pem: "${tls_self_signed_cert.root.cert_pem}",
        validity_period_hours: 365 * 24,
        allowed_uses: [
          "digital_signature",
          "server_auth",
          "client_auth",
        ],
      },
    },
    null_resource: {
      kubeconfig: {
        provisioner: [{
          "local-exec": {
            command: "echo '%s' > kubeconfig.json" % std.manifestJson({
              apiVersion: "v1",
              kind: "Config",
              users: [{
                name: "admin",
                user: {
                  "client-certificate-data": "${base64encode(tls_private_key.admin.private_key_pem)}",
                  "client-key-data": "${base64encode(tls_self_signed_cert.root.cert_pem)}",
                },
              }],
              clusters: [{
                name: "local",
                cluster: {
                  "certificate-authority-data": "${base64encode(tls_self_signed_cert.root.cert_pem)}",
                  #server: "https://%(master_ip)s" % cfg,
                },
              }],
              contexts: [{
                context: {
                  cluster: "local",
                  user: "admin",
                },
                name: "service-account-context",
              }],
              "current-context": "service-account-context",
            }
            ),
          },
        }],
      },
    },
  },
}
