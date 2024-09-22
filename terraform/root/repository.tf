################################################################################
# Repository
################################################################################
# ECRPullThroughCacheRule定義
# パブリックECRのイメージをキャッシュしbuildを高速化する
resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
    ecr_repository_prefix = "ecr-public-${var.environment}"
    upstream_registry_url = "public.ecr.aws"
}
