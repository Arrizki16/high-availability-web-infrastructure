resource "aws_vpc" "rpl-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "rpl-vpc"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.rpl-vpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2"
  }
}

resource "aws_subnet" "subnet-3" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "ap-southeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-3"
  }
}

resource "aws_security_group" "rpl-security-group" {
  name = "rpl-security-group"
  vpc_id = aws_vpc.rpl-vpc.id
  depends_on = [ aws_vpc.rpl-vpc ]
  description = "Allow SSH, HTTP, HTTPS for ingress and all traffic for outbound"

  ingress {
    description = "Allow inbound HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow inbound SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_default_route_table" "default-routing-table" {
  default_route_table_id = aws_vpc.rpl-vpc.main_route_table_id

  tags = {
    Name = "default-routing-table"
  }
}

resource "aws_route" "public-route" {
  route_table_id = aws_default_route_table.default-routing-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}