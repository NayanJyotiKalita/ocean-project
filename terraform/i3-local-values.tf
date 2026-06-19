locals {
  environment = var.environment
  name = "${var.environment}"
  common_tags = {
    environment = local.environment
  }
}
