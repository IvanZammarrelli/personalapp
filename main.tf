provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_gateway"
  }
}

# Create two public subnets
resource "aws_subnet" "my_public_subnet_1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "my_public_subnet_1"
  }
}

resource "aws_subnet" "my_public_subnet_2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "my_public_subnet_2"
  }
}

# Create two private subnets
resource "aws_subnet" "my_private_subnet_1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "my_private_subnet_1"
  }
}

resource "aws_subnet" "my_private_subnet_2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "my_private_subnet_2"
  }
}

# Public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate the public route table with the public subnets
resource "aws_route_table_association" "public_route_table_association_1" {
  subnet_id      = aws_subnet.my_public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_route_table_association_2" {
  subnet_id      = aws_subnet.my_public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# NAT Gateway for private subnets internet access
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.my_public_subnet_1.id
  depends_on    = [aws_internet_gateway.my_gateway]

  tags = {
    Name = "nat_gateway"
  }
}

# Private route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "private_route_table"
  }
}

# Associate the private route table with the private subnets
resource "aws_route_table_association" "private_route_table_association_1" {
  subnet_id      = aws_subnet.my_private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_route_table_association_2" {
  subnet_id      = aws_subnet.my_private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

