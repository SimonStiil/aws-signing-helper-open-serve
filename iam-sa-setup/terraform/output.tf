output "trust_anchor_arn" {
  value = aws_rolesanywhere_trust_anchor.self_managed_ca_trust_anchor.arn
}

output "profile_ca_arn" {
  value = aws_rolesanywhere_profile.self_managed_ca_profile.arn
}

output "role_arn" {
  value = aws_iam_role.self_managed_ca_role.arn
}