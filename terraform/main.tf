provider "aws" {
  region  = module.config.region
  profile = "terraform"
}

// resources
module "resources" {
  source = "./resources/"
}

// config
module "config" {
  source = "./config"
}

// bathces
module "ecs_ts_dev_template" {
  source    = "./modules/ecs_dev_ts_template"
  resources = module.resources
  config    = module.config
}

// services
module "openapi_sample" {
  source    = "./modules/openapi_sample"
  resources = module.resources
  config    = module.config
}
