output "key_name" {
  description = "Name of the key pair"
  value       = aws_key_pair.ec2_keypair.key_name
}

output "key_pair_id" {
  description = "Key pair ID"
  value       = aws_key_pair.ec2_keypair.key_pair_id
}

output "fingerprint" {
  description = "Key pair fingerprint"
  value       = aws_key_pair.ec2_keypair.fingerprint
}

output "private_key" {
  description = "Private key"
  value       = tls_private_key.private_key.private_key_pem
  sensitive   = true
}
