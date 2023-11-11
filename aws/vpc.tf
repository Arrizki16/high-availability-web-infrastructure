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

resource "aws_subnet" "private-a" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "private-a"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-southeast-1b"
  # map_public_ip_on_launch = true

  tags = {
    Name = "private-b"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-a"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id = aws_vpc.rpl-vpc.id
  cidr_block = "10.0.11.0/24"
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-b"
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

resource "aws_eip" "nat_gateway" {
  vpc = true
  depends_on = [ aws_internet_gateway.igw ]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id = aws_subnet.public-a.id
  tags = {
    Name = "Nat-Gateway"
  }
  depends_on = [ aws_eip.nat_gateway ]
}

resource "aws_route_table" "public-route" {
  vpc_id = aws_vpc.rpl-vpc.id
  tags = {
    Name = "public-subnets-routing-table"
  }
}

resource "aws_route_table" "private-route" {
  vpc_id = aws_vpc.rpl-vpc.id
  tags = {
    Name = "private-subnets-routing-table"
  }
}

resource "aws_route" "public-internet-igw-route" {
  route_table_id = aws_route_table.public-route.id
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "nat_gateway_route" {
  route_table_id = aws_route_table.private-route.id
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public-a-route" {
  route_table_id = aws_route_table.public-route.id
  subnet_id = aws_subnet.public-a.id
}

resource "aws_route_table_association" "public-b-route" {
  route_table_id = aws_route_table.public-route.id
  subnet_id = aws_subnet.public-b.id
}

resource "aws_route_table_association" "private-a-route" {
  route_table_id = aws_route_table.private-route.id
  subnet_id = aws_subnet.private-a.id
}

resource "aws_route_table_association" "private-b-route" {
  route_table_id = aws_route_table.private-route.id
  subnet_id = aws_subnet.private-b.id
}

# resource "aws_route_table_association" "public-gateway" {
#   subnet_id = aws_subnet.public-subnet.id
#   route_table_id = aws_route_table.public-gateway.id
# }

# resource "aws_default_route_table" "default-routing-table" {
#   default_route_table_id = aws_vpc.rpl-vpc.main_route_table_id

#   tags = {
#     Name = "default-routing-table"
#   }
# }

# resource "aws_route" "public-route" {
#   route_table_id = aws_default_route_table.default-routing-table.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id = aws_internet_gateway.igw.id
# }

# resource "aws_route_table_association" "public-route" {
#   subnet_id = aws
# }