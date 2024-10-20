########################################################################################
# Outputs
########################################################################################
# ECRリポジトリのARN
output "ecr_repository_arn" {
    description = "ECRリポジトリのARN"
    value       = aws_ecr_repository.main.arn
}

# ECRリポジトリのURL
output "ecr_repository_url" {
    description = "ECRリポジトリのURL"
    value       = aws_ecr_repository.main.repository_url
}
