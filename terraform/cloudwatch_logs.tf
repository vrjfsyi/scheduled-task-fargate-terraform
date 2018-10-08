## References
## https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html#create_awslogs_loggroups

resource "aws_cloudwatch_log_group" "fargate_cloudwatch_log_group" {
  name = "/fargate/${var.application}/${var.environment}"

  tags {
    Name        = "/fargate/${var.application}/${var.environment}"
    application = "${var.application}"
    environemt  = "${var.environment}"
  }
}
