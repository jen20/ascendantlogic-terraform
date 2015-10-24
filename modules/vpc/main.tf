provider "aws" {}

resource "aws_vpc" "module" {
  cidr_block = "${var.cidr}"

  tags { Name = "${var.name}" }
}

resource "aws_internet_gateway" "module" {
  vpc_id = "${aws_vpc.module.id}"
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.module.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.module.id}"
  }

  tags { Name = "${var.name}-public" }
}

resource "aws_subnet" "public" {
  count = "${length(split(",", var.public_subnets))}"

  vpc_id = "${aws_vpc.module.id}"
  cidr_block = "${element(split(",", var.public_subnets), count.index)}"
  availability_zone = "${element(split(",", var.az_names), count.index)}"

  map_public_ip_on_launch = true

  tags { Name = "${var.name}-public" }
}

resource "aws_route_table_association" "public" {
  count = "${length(split(",", var.public_subnets))}"

  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_instance" "nat" {
  count = "${length(split(",", var.private_subnets))}"

  ami = "${var.nat_ami}"
  instance_type = "${var.nat_instance_size}"

  source_dest_check = false

  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  security_groups = ["${split(",", var.nat_security_groups)}"]

  tags {
    Name = "${var.name}-#{aws_subnet.public.*.availability_zone, count.index}-nat"
  }
}

resource "aws_route_table" "private" {
  count = "${length(split(",", var.private_subnets))}"

  vpc_id = "${aws_vpc.module.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${element(aws_instance.nat.*.id, count.index)}"
  }

  tags { Name = "${var.name}-private" }
}

resource "aws_subnet" "private" {
  count = "${length(split(",", var.private_subnets))}"

  vpc_id = "${aws_vpc.module.id}"
  cidr_block = "${element(split(",", var.private_subnets), count.index)}"
  availability_zone = "${element(split(",", var.az_names), count.index)}"

  tags { Name = "${var.name}-private" }
}

resource "aws_route_table_association" "private" {
  count = "${length(split(",", var.private_subnets))}"

  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"

  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
