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
  }


  deployment_config = local.deployment_map[var.deployment_strategy].config
  deployment_type   = local.deployment_map[var.deployment_strategy].type
  deployment_option = local.deployment_map[var.deployment_strategy].option
}
