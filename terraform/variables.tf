variable "aws_region" {
  type = "string"
}

variable "application" {
  type = "string"
}

variable "environment" {
  type = "string"
}

variable "scheduled_ecs_task_cloudwatch_event_rule_schedule_expression" {
  type = "string"
}

locals {
  ecr_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}
