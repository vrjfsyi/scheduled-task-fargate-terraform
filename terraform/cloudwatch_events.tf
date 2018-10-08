# CloudWatch and ECS Task

resource "aws_cloudwatch_event_rule" "scheduled_ecs_task_cloudwatch_event_rule" {
  name = "${var.application}_${var.environment}_scheduled_ecs_task"

  schedule_expression = "${var.scheduled_ecs_task_cloudwatch_event_rule_schedule_expression}"
  description = "cloudwatch event rule that invokes fargate task"
  is_enabled = "false"
}

resource "aws_cloudwatch_event_target" "scheduled_ecs_task_cloudwatch_event_target" {
  rule = "${aws_cloudwatch_event_rule.scheduled_ecs_task_cloudwatch_event_rule.name}"
  arn = "${aws_ecs_cluster.ecs_cluster.arn}"
  role_arn = "${aws_iam_role.scheduled_ecs_task_cloudwatch_event_target_iam_role.arn}"

  ecs_target {

    group = "scheduled task"

    launch_type = "FARGATE"

    network_configuration = {
      security_groups = [
        "${aws_security_group.scheduled_task_security_group.id}",
      ]

      subnets = [
        "${aws_subnet.private_subnet.*.id}",
      ]

      assign_public_ip = "false"
    }

    platform_version = "1.2.0"
    task_count = "1"

    task_definition_arn = "arn:aws:ecs:${var.aws_region}:${local.account_id}:task-definition/${aws_ecs_task_definition.ecs_task_definition.family}"
  }
}

# CloudWatch Event Target IAM Role

## References
## https://docs.aws.amazon.com/AmazonECS/latest/developerguide/CWE_IAM_role.html
## https://docs.aws.amazon.com/IAM/latest/UserGuide/list_amazonec2containerservice.html#amazonec2containerservice-RunTask

data "aws_iam_policy_document" "scheduled_ecs_task_cloudwatch_event_target_iam_policy_document" {
  statement {
    sid = "ECSRunTask"
    effect = "Allow"

    actions = [
      "ecs:RunTask",
    ]

    resources = [
      "arn:aws:ecs:${var.aws_region}:${local.account_id}:task-definition/${aws_ecs_task_definition.ecs_task_definition.family}:*",
    ]

    condition {
      test = "ArnEquals"
      variable = "ecs:cluster"

      values = [
        "${aws_ecs_cluster.ecs_cluster.arn}",
      ]
    }
  }

  statement {
    sid = "PassRoleToECSTask"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      //      "${aws_iam_role.ecs_task_execution_iam_role.arn}",
      "*",
    ]

    condition {
      test = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "scheduled_ecs_task_cloudwatch_event_target_iam_policy" {
  name = "${var.application}-${var.environment}_scheduled_ecs_task_cloudwatch_event_rule"
  path = "/"
  description = "iam policy for cloudwatch event target that invokes fargate task"

  policy = "${data.aws_iam_policy_document.scheduled_ecs_task_cloudwatch_event_target_iam_policy_document.json}"
}

data "aws_iam_policy_document" "scheduled_ecs_task_cloudwatch_event_target_assume_role_iam_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "events.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "scheduled_ecs_task_cloudwatch_event_target_iam_role" {
  name = "${var.application}_${var.environment}_scheduled_ecs_task_cloudwatch_event_rule"
  assume_role_policy = "${data.aws_iam_policy_document.scheduled_ecs_task_cloudwatch_event_target_assume_role_iam_policy_document.json}"
  description = "iam role for cloudwatch event target that invokes fargate task"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_event_target_iam_role_policy_attachment" {
  role = "${aws_iam_role.scheduled_ecs_task_cloudwatch_event_target_iam_role.name}"
  policy_arn = "${aws_iam_policy.scheduled_ecs_task_cloudwatch_event_target_iam_policy.arn}"
}
