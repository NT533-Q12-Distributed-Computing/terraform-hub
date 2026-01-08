output "k0s_sg_id" {
  value = aws_security_group.k0s.id
}

output "openvpn_sg_id" {
  value = aws_security_group.openvpn.id
}

output "observability_sg_id" {
  value = aws_security_group.observability.id
}

output "eks_control_plane_sg_id" {
  value = aws_security_group.eks_control_plane.id
}

output "eks_node_sg_id" {
  value = aws_security_group.eks_nodes.id
}
