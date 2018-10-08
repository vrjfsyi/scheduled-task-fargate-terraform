resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.application}_${var.environment}_ecs_cluster"
}

# Container Definitions

locals {
  container_definitions_awslogs_stream_prefix = "ecs"
}

data "template_file" "ecs_task_container_definitions_template_file" {
  template = "${file("container_definitions/application.json.tpl")}"

  vars {
    container_name   = "${var.application}-${var.environment}"
    image_registry   = "${local.ecr_registry}"
    image_repository = "${aws_ecr_repository.ecr_repository.name}"
    image_tag        = "latest"
    environment      = "${var.environment}"

    ## https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html#create_awslogs_logdriver_options
    awslogs_group = "${aws_cloudwatch_log_group.fargate_cloudwatch_log_group.name}"

    awslogs_region = "${var.aws_region}"

    awslogs_stream_prefix = "${local.container_definitions_awslogs_stream_prefix}"
  }
}

# ECS Task Definition

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                = "${var.application}_${var.environment}_family"
  container_definitions = "${data.template_file.ecs_task_container_definitions_template_file.rendered}"

  task_role_arn      = "${aws_iam_role.ecs_task_iam_role.arn}"
  execution_role_arn = "${aws_iam_role.ecs_task_execution_iam_role.arn}"

  # fargate requires that network mode must be awsvpc
  ## https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#network_mode
  network_mode = "awsvpc"

  ## https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size

  cpu    = "256"
  memory = "512"
  requires_compatibilities = [
    "FARGATE",
  ]
}

# Task IAM Role

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html

data "aws_iam_policy_document" "ecs_task_iam_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
    ]

    resources = [
      "${aws_kms_key.kmv_key.arn}",
    ]
  }
}

resource "aws_iam_policy" "ecs_task_iam_policy" {
  name        = "${var.application}-${var.environment}_ecs_task"
  path        = "/"
  policy      = "${data.aws_iam_policy_document.ecs_task_execution_iam_policy_document.json}"
  description = "iam policy for ecs task role"
}

data "aws_iam_policy_document" "ecs_task_assume_role_iam_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ecs_task_iam_role" {
  name               = "${var.application}_${var.environment}_ecs_task"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_assume_role_iam_policy_document.json}"
  description        = "iam role for ecs task"
}

resource "aws_iam_role_policy_attachment" "ecs_task_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_task_iam_role.name}"
  policy_arn = "${aws_iam_policy.ecs_task_iam_policy.arn}"
}

# Task Execution Role

## https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html

data "aws_iam_policy_document" "ecs_task_execution_iam_policy_document" {
  statement {
    sid    = "GetAuthorizationToken"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid    = "GetImage"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]

    resources = [
      "${aws_ecr_repository.ecr_repository.arn}",
    ]
  }

  statement {
    sid    = "CreateAndPutLog"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.fargate_cloudwatch_log_group.name}",
      "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.fargate_cloudwatch_log_group.name}:*",
    ]
  }
}

resource "aws_iam_policy" "ecs_task_execution_iam_policy" {
  name        = "${var.application}_${var.environment}_ecs_task_execution"
  path        = "/"
  policy      = "${data.aws_iam_policy_document.ecs_task_execution_iam_policy_document.json}"
  description = "iam policy for ecs task execution role"
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role_iam_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_iam_role" {
  name               = "${var.application}_${var.environment}_ecs_task_execution"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_task_execution_assume_role_iam_policy_document.json}"
  description        = "iam role for ecs task execution"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_iam_role_policy_attachment" {
  role       = "${aws_iam_role.ecs_task_execution_iam_role.name}"
  policy_arn = "${aws_iam_policy.ecs_task_execution_iam_policy.arn}"
}

# Security group

resource "aws_security_group" "scheduled_task_security_group" {
  name        = "${var.application}_${var.environment}_scheduled_task"
  description = "security group for scheduled task"
  vpc_id      = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.application}_${var.environment}_scheduled_task"
    application = "${var.application}"
    environment = "${var.environment}"
  }
}

resource "aws_security_group_rule" "scheduled_task_egress_all_security_group_rule" {
  type = "egress"

  cidr_blocks = [
    "0.0.0.0/0",
  ]

  from_port         = 0
  protocol          = "-1"
  security_group_id = "${aws_security_group.scheduled_task_security_group.id}"
  to_port           = 0
}
