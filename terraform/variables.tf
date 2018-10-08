variable "aws_region" {
  type = "string"
}

variable "application" {
  type = "string"
}

variable "environment" {
  type = "string"
}

locals {
  ecr_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}
