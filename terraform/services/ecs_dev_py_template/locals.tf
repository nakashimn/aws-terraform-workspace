################################################################################
# LocalParams
################################################################################
locals {
  name            = "ecs-dev-py-template"
  repository_name = "ecs_dev_py_template"
  bitbucket_repository_url = "https://x-token-auth:${var.bitbucket_access_token}@bitbucket.org/nakashimn/ecs_dev_py_template.git"
  version         = "develop"
}
