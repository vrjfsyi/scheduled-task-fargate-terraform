# https://www.terraform.io/docs/configuration/providers.html#provider-versions
# https://github.com/terraform-providers/terraform-provider-aws/blob/master/CHANGELOG.md

provider "aws" {
  version = "1.39.0"
  region  = "${var.aws_region}"
}
