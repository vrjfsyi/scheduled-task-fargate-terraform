data "aws_caller_identity" "caller_identity" {}

locals {
  account_id = "${data.aws_caller_identity.caller_identity.account_id}"
}
