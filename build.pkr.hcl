build {
  name = "graphdb-ami"
  sources = [
    "source.amazon-ebs.ubuntu_x86_64",
    "source.amazon-ebs.ubuntu_arm64"
  ]

  provisioner "file" {
    sources = [
      "./files/cloudwatch-agent-config.json",
      "./files/graphdb.env",
      "./files/graphdb.service",
      "./files/graphdb-cluster-proxy.env",
      "./files/graphdb-cluster-proxy.service",
      "./files/prometheus.yaml",
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    environment_vars = [
      "GRAPHDB_VERSION=${var.graphdb_version}",
    ]
    execute_command = "{{ .Vars }} sudo -E bash '{{ .Path }}'"
    scripts = [
      "./files/1-setup.sh",
      "./files/2-hardening.sh",
      "./files/3-install-graphdb.sh",
    ]

    max_retries = var.build_retries
  }

  provisioner "breakpoint" {
    disable = !var.build_breakpoint_enabled
    note    = "Paused for debugging — SSH in now"
  }

  post-processor "manifest" {
    output = var.manifest_path
    custom_data = {
      graphdb_version = var.graphdb_version
    }
  }
}
