output "ecr_registry" {
  value = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

output "ecr_repository" {
  value = "${aws_ecr_repository.ecr_repository.name}"
}