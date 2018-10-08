output "ecr_registry" {
  value = "${local.ecr_registry}"
}

output "ecr_repository" {
  value = "${aws_ecr_repository.ecr_repository.name}"
}
