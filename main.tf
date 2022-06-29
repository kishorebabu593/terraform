

resource "aws_vpc" "gartnervpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    name = "gartnervpc"
  }
}

resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.gartnervpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    name = "pubsubnet"
  }
}

resource "aws_subnet" "privsub" {
  vpc_id     = aws_vpc.gartnervpc.id
  cidr_block = "10.0.2.0/24"
  tags = {
    name = "privsubnet"
  }
}

resource "aws_internet_gateway" "gartnerigw" {
  vpc_id = aws_vpc.gartnervpc.id
  tags = {
    name = "gartnerinternetgateway"
  }
}

resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.gartnervpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gartnerigw.id
  }
  tags = {
    name = "publicroutetable"
  }
}

resource "aws_route_table_association" "pubassociation" {
  subnet_id      = aws_subnet.pubsub.id
  route_table_id = aws_route_table.pubrt.id
}

resource "aws_eip" "myeip" {
  vpc = true
}

resource "aws_nat_gateway" "gnat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsub.id
  tags = {
    name = "gartnernatgw"
  }
}

resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.gartnervpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.gnat.id
  }
  tags = {
    name = "privateroutetable"
  }
}


resource "aws_route_table_association" "privassociation" {
  subnet_id      = aws_subnet.privsub.id
  route_table_id = aws_route_table.privrt.id
}

resource "aws_security_group" "allowall" {
  description = "To allow all network traffics"
  vpc_id      = aws_vpc.gartnervpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allowall"
  }
}

resource "aws_instance" "pubec2" {
  ami                         = "ami-0727ea5edebc000a0"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.pubsub.id
  key_name                    = "windows0622"
  vpc_security_group_ids      = ["${aws_security_group.allowall.id}"]
  associate_public_ip_address = true
}

resource "aws_instance" "privec2" {
  ami                    = "ami-0727ea5edebc000a0"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.privsub.id
  key_name               = "windows0622"
  vpc_security_group_ids = ["${aws_security_group.allowall.id}"]
}


