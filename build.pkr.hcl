build {
  name = "graphdb-ami"
  sources = [
    "source.amazon-ebs.ubuntu-x86-64",
    "source.amazon-ebs.ubuntu-arm64"
  ]

  provisioner "file" {
    sources = [
      "./files/graphdb.service",
      "./files/graphdb-cluster-proxy.service",
      "./files/install_graphdb.sh",
      "./files/cloudwatch-agent-config.json",
      "./files/prometheus.yaml",
      "./files/ebs_volume.sh",
      "./files/register_route53.sh",
      "./files/create_backup.sh"
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    environment_vars = [
      "GRAPHDB_VERSION=${var.gdb_version}",
    ]
    inline      = ["sudo -E bash /tmp/install_graphdb.sh"]
    max_retries = 3
  }
}
