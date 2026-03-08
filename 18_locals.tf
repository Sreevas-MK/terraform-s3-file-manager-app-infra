locals {
  deployment_map = {
    "inplace-all" = {
      config = "CodeDeployDefault.AllAtOnce"
      type   = "IN_PLACE"
      option = null
    }

    "rolling" = {
      config = "CodeDeployDefault.OneAtATime"
      type   = "IN_PLACE"
      option = null
    }

    "bluegreen" = {
      config = "CodeDeployDefault.AllAtOnce"
      type   = "BLUE_GREEN"
      option = "WITH_TRAFFIC_CONTROL"
    }

    "canary" = {
      config = "CodeDeployDefault.Canary10Percent5Minutes"
      type   = "BLUE_GREEN"
      option = "WITH_TRAFFIC_CONTROL"
    }
  }

  deployment_config = local.deployment_map[var.deployment_strategy].config
  deployment_type   = local.deployment_map[var.deployment_strategy].type
  deployment_option = local.deployment_map[var.deployment_strategy].option
}
