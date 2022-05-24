server           = true
bootstrap_expect = 1

connect {
  enabled = true
}

addresses {
  grpc = "127.0.0.1"
}

ports {
  grpc     = 8502
  serf_lan = 7301
  server   = 7300
}

performance {
  raft_multiplier = 5
}

tls {
  internal_rpc {
    verify_server_hostname = true
  }

  defaults {
    verify_incoming = true
    verify_outgoing = true
    ca_file         = "/opt/consul/tls/consul-agent-ca.pem"
    cert_file       = "/opt/consul/tls/dc1-server-consul-0.pem"
    key_file        = "/opt/consul/tls/dc1-server-consul-0-key.pem"
  }
}

auto_encrypt {
  allow_tls = true
}