build {
  name = "graphdb-ami"
  sources = [
    "source.amazon-ebs.ubuntu_x86_64",
    "source.amazon-ebs.ubuntu_arm64"
  ]

  provisioner "file" {
    sources = [
      "./files/graphdb.service",
      "./files/graphdb-cluster-proxy.service",
      "./files/install_graphdb.sh",
      "./files/cloudwatch-agent-config.json",
      "./files/prometheus.yaml"
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    environment_vars = [
      "GRAPHDB_VERSION=${var.graphdb_version}",
    ]
    inline      = ["sudo -E bash /tmp/install_graphdb.sh"]
    max_retries = 3
  }
}
