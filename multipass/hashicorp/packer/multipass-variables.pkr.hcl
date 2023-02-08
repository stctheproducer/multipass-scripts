variable "iso_url" {
  type = string
  default = "http://cloud-images.ubuntu.com/releases/bionic/release/ubuntu-18.04-server-cloudimg-amd64.img"
}

variable "iso_checksum" {
  type =  string
  default = "sha256:ba635487f94020bd5c6dba3f1751bbb856407cef3acafb82dc455bee72a4673f"
}

variable "disk_size" {
  type = number
  default = 5120
}

variable "ssh_password" {
  type = string
  default = "packerpassword"
  sensitive = true
}

variable "build_name" {
  type = string
  default = "multipass"
}

variable "script_path" {
  type = string
}