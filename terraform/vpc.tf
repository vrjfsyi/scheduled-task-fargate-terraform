data "aws_availability_zones" "availability_zones" {}

locals {
  availability_zone_names = [
    "${data.aws_availability_zones.availability_zones.names}",
  ]

  vpc_cidr_block = "192.168.0.0/21"

  num_of_public_subnets = "1"

  public_subnet_cidr_blocks = [
    "192.168.1.0/24",
  ]

  num_of_private_subnets = "1"

  privatve_subnet_cidr_blocks = [
    "192.168.4.0/24",
  ]

  public_subnet_ids  = "${aws_subnet.public_subnet.*.id}"
  private_subnet_ids = "${aws_subnet.private_subnet.*.id}"
}

# VPC

resource "aws_vpc" "vpc" {
  cidr_block = "${local.vpc_cidr_block}"

  tags {
    Name        = "${var.application}_${var.environment}"
    application = "${var.application}"
    environment = "${var.environment}"
  }
}

# Public Subnet

resource "aws_eip" "eip" {
  count = "${local.num_of_public_subnets}"

  vpc = true

  tags {
    Name        = "${var.application}_${var.environment}_eip_${count.index}"
    application = "${var.application}"
    environment = "${var.environment}"
  }

  depends_on = [
    "aws_internet_gateway.internet_gateway",
  ]
}

resource "aws_subnet" "public_subnet" {
  count = "${local.num_of_public_subnets}"

  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(local.public_subnet_cidr_blocks, count.index)}"
  availability_zone = "${element(local.availability_zone_names, count.index)}"

  tags {
    Name              = "${var.application}-${var.environment}_public_subnet_${element(local.availability_zone_names, count.index)}"
    application       = "${var.application}"
    environment       = "${var.environment}"
    availability_zone = "${element(local.availability_zone_names, count.index)}"
    subnet_type       = "public"
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.application}-${var.environment}_public_subnet_route_table"
    application = "${var.application}"
    environment = "${var.environment}"
  }
}

resource "aws_route" "public_subnet_internet_gateway_route" {
  route_table_id         = "${aws_route_table.public_subnet_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.internet_gateway.id}"
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
  count = "${local.num_of_public_subnets}"

  subnet_id      = "${element(local.public_subnet_ids, count.index)}"
  route_table_id = "${aws_route_table.public_subnet_route_table.id}"
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.application}_${var.environment}_internet_gateway"
    application = "${var.application}"
    environment = "${var.environment}"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  count = "${local.num_of_public_subnets}"

  subnet_id     = "${element(local.public_subnet_ids,count.index )}"
  allocation_id = "${element(aws_eip.eip.*.id, count.index)}"

  tags {
    Name        = "${var.application}_${var.environment}_nat_gateway_${count.index}"
    application = "${var.application}"
    environment = "${var.environment}"
  }
}

# Private Subnet

resource "aws_subnet" "private_subnet" {
  count = "${local.num_of_private_subnets}"

  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(local.privatve_subnet_cidr_blocks, count.index)}"
  availability_zone = "${element(local.availability_zone_names, count.index)}"

  tags {
    Name              = "${var.application}_${var.environment}_private_subnet_${element(local.availability_zone_names, count.index)}"
    application       = "${var.application}"
    environment       = "${var.environment}"
    availability_zone = "${element(local.availability_zone_names, count.index)}"
    subnet_type       = "private"
  }
}

resource "aws_route_table" "private_subnet_route_table" {
  count = "${local.num_of_private_subnets}"

  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "${var.application}_${var.environment}_private_subnet_route_table_${count.index}"
    application = "${var.application}"
    environment = "${var.environment}"
    subnet_type = "private"
  }
}

resource "aws_route" "private_subnet_nat_gateway_route" {
  count = "${local.num_of_private_subnets}"

  route_table_id         = "${element(aws_route_table.private_subnet_route_table.*.id,count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat_gateway.*.id,count.index )}"
}

resource "aws_route_table_association" "private_subnet_route_table_association" {
  count          = "${local.num_of_private_subnets}"
  subnet_id      = "${element(local.private_subnet_ids, count.index)}"
  route_table_id = "${element(aws_route_table.private_subnet_route_table.*.id,count.index )}"
}
