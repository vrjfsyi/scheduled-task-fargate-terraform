resource "aws_kms_key" "kmv_key" {
  description = "kms for ${var.application} in ${var.environment}"
  key_usage   = "ENCRYPT_DECRYPT"

  tags {
    Name        = "kms for ${var.application} in ${var.environment}"
    application = "${var.application}"
    environment = "${var.environment}"
  }
}
