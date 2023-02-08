packer {
  required_version = ">= 1.7.0"
}

source "qemu" "multipass" {
  iso_url                 = var.iso_url
  iso_checksum            = var.iso_checksum
  disk_discard            = "unmap"
  disk_image              = true
  disk_interface          = "virtio-scsi"
  disk_size               = var.disk_size
  http_directory          = "cloud-data"
  qemuargs                = [["-smbios", "type=1,serial=ds=nocloud-net;instance-id=packer;seedfrom=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"]]
  ssh_password            = var.ssh_password
  ssh_username            = "packer"
  ssh_timeout             = "20m"
  pause_before_connecting = "5m"
  format                  = "qcow2"
  use_default_display     = true
}

build {
  name    = var.build_name
  sources = ["source.qemu.multipass"]

  provisioner "file" {
    source      = "app.tar.gz"
    content     = ""
    destination = "/tmp/app.tar.gz"
  }


  provisioner "shell" {
    script = var.script_path
  }

  provisioner "shell" {
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"
    script          = "./scripts/cleanup.sh"
  }

  post-processors {
    post-processor "manifest" {
      strip_path = true
      output     = "packer_{{.BuildName}}_manifest.json"
    }

    post-processor "checksum" {
      checksum_types      = ["sha256"]
      keep_input_artifact = true
      output              = "packer_{{.BuildName}}_{{.ChecksumType}}.checksum"
    }
  }
}
