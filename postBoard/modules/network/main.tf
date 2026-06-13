data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-${count.index + 1}"
  })
}

resource "aws_subnet" "db" {
  count = length(var.db_subnet_cidr_blocks)

  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = var.db_subnet_cidr_blocks[count.index]
  vpc_id            = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-${count.index + 1}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.default_route_cidr_block
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-rt"
  })
}

resource "aws_route_table_association" "db" {
  count = length(aws_subnet.db)

  route_table_id = aws_route_table.db.id
  subnet_id      = aws_subnet.db[count.index].id
}
