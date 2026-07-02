output "key_arn" {
  description = "ARN of the KMS CMK used by S3, the target Aurora cluster, and DMS."
  value       = module.kms.key_arn
}

output "key_id" {
  description = "ID of the KMS CMK."
  value       = module.kms.key_id
}
