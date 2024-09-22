#! /bin/bash

################################################################################
# [概要]
#   Backend切り替え用スクリプト
#   対象のリソースがあるディレクトリ内から実行することでTerraformBackendを切り替える
#
# [args]
#   -e, --environment: 切替先の環境(pro/stg/dev)
################################################################################

# set environment
environment=""
while (( $# > 0 )); do
    case $1 in
        -e | --environment )
            if [[ $2 == "pro" ]]; then
                environment=$2
            elif [[ $2 == "stg" ]]; then
                environment=$2
            elif [[ $2 == "dev" ]]; then
                environment=$2
            else
                echo -e "\e[31m[Error]set valid environment.\e[0m"
                exit
            fi
            shift
            ;;
    esac
    shift
done

# check args
if [ -z $environment ]; then
    echo -e "\e[41m[Error]set environment.\e[0m"
    exit
fi

# path
SCRIPT_DIR=$(cd $(dirname $0); pwd)
CONFIG_DIR="$(dirname $SCRIPT_DIR)/terraform_conf"

# switch backend
terraform init -reconfigure -backend-config "${CONFIG_DIR}/${environment}.conf"
