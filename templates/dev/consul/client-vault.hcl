tls {
  internal_rpc {
    verify_server_hostname = true
  }

  defaults {
    verify_incoming = false
    verify_outgoing = true
    ca_file         = "/opt/consul/tls/consul-agent-ca.pem"
  }
}

ports {
  serf_lan = 7301
  server   = 7300
}

auto_encrypt {
  tls = true
}

performance {
  raft_multiplier = 5
}