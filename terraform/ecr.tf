resource "aws_ecr_repository" "ecr_repository" {
  name = "${var.application}_${var.environment}"
}
