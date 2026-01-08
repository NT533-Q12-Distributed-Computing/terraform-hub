# =====================================================
# Kubernetes (k0s) Inventory - Staging
# =====================================================
resource "local_file" "kubernetes_inventory" {
  filename = "${path.root}/../../../ansible/inventories/staging/kubernetes.ini"

  content = <<-EOF
[k0s_controller]
controller ansible_host=${module.k0s.controller.private_ip}

[k0s_workers]
%{for idx, inst in module.k0s.workers~}
worker-${idx + 1} ansible_host=${inst.private_ip}
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
  filename = "${path.root}/../../../ansible/inventories/staging/observability.ini"

  content = <<-EOF
# ================================
# Observability Inventory (Staging)
# ================================

[monitoring]
obser-1 ansible_host=${module.observability.instances[0].private_ip}

[logging]
obser-2 ansible_host=${module.observability.instances[1].private_ip}

[all:vars]
loki_host=${module.observability.instances[1].private_ip}
EOF
}

# =====================================================
# OpenVPN Inventory - Staging
# =====================================================
resource "local_file" "openvpn_inventory" {
  filename = "${path.root}/../../../ansible/inventories/staging/openvpn.ini"

  content = <<-EOF
[openvpn]
vpn ansible_host=${module.openvpn.public_ip}
EOF
}
