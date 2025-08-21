# VPC
resource "aws_vpc" "vpc2" {
  cidr_block       = "20.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "yjs-vpc2"
  }
}

# Subnet
resource "aws_subnet" "vpc2_pri_sub_az1" {
  vpc_id = aws_vpc.vpc2.id
  cidr_block = "20.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "yjs-vpc2-pri-az1"
  }
}

# Private Instance
resource "aws_instance" "vpc2_instance" {
  ami           = "ami-0897f20d7e803af8f"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.vpc2_pri_sub_az1.id
  associate_public_ip_address = "false"
  vpc_security_group_ids = [aws_security_group.vpc2_ec2_sg.id]
  tags = {
    Name = "yjs-vp2-instance"
  }
}

# Routing Table
resource "aws_route_table" "vpc2_peering_rt" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "10.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    Name = "yjs-vpc2-peering-rt"
  }
}

resource "aws_route_table_association" "vpc2_peering_rt_assoc" {
  subnet_id      = aws_subnet.vpc2_pri_sub_az1.id
  route_table_id = aws_route_table.vpc2_peering_rt.id
}

# Security Group
resource "aws_security_group" "vpc2_ec2_sg" {
  name        = "yjs-vpc2-sg"
  vpc_id      = aws_vpc.vpc2.id
  tags = {
    Name = "yjs-vpc2-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpc2_ec2_ingress_22" {
  security_group_id = aws_security_group.vpc2_ec2_sg.id
  referenced_security_group_id = aws_security_group.ec2_sg.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "vpc2_ec2_egress_all" {
  security_group_id = aws_security_group.vpc2_ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
