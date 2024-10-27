################################################################################
# LocalParams
################################################################################
locals {
  # サービスグループの名称
  service_group = "${var.vendor}-${var.region}-${var.service}"

  # AWSアベイラビリティゾーンの情報
  availability_zones = [
    for index, name in data.aws_availability_zones.available.names :
    {
      name    = name
      zone_id = data.aws_availability_zones.available.zone_ids[index]
    }
  ]
}
