#! /bin/bash

################################################################################
# [概要]
#   Backend切り替え用スクリプト
#   対象のリソースがあるディレクトリ内から実行することでTerraformBackendを切り替える
################################################################################
# path
SCRIPT_DIR=$(cd $(dirname $0); pwd)
CONFIG_DIR="$(dirname $SCRIPT_DIR)/terraform_conf/"

# switch backend
terraform init
