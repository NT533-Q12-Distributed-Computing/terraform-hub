# =====================================================
# Kubernetes (k0s) Inventory - Staging
# =====================================================
resource "local_file" "kubernetes_inventory" {
  filename = "${var.ansible_inventory_dir}/kubernetes.ini"

  content = <<-EOF
[k0s_controller]
controller ansible_host=${module.k0s.controller.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(var.ssh_key_path)}

[k0s_workers]
%{for idx, inst in module.k0s.workers~}
worker-${idx + 1} ansible_host=${inst.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(var.ssh_key_path)}
%{endfor~}

[k0s_cluster:children]
k0s_controller
k0s_workers
EOF
}

# =====================================================
# Observability Inventory - Staging
# =====================================================
resource "local_file" "observability_inventory" {
  filename = "${var.ansible_inventory_dir}/observability.ini"

  content = <<-EOF
[monitoring]
obser-1 ansible_host=${module.observability.instances[0].private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(var.ssh_key_path)}

[logging]
obser-2 ansible_host=${module.observability.instances[1].private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(var.ssh_key_path)}

[all:vars]
loki_host=${module.observability.instances[1].private_ip}
EOF
}

# =====================================================
# OpenVPN Inventory - Staging
# =====================================================
resource "local_file" "openvpn_inventory" {
  filename = "${var.ansible_inventory_dir}/openvpn.ini"

  content = <<-EOF
[openvpn]
vpn ansible_host=${module.openvpn.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${abspath(var.ssh_key_path)}
EOF
}
