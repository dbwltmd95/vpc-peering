# VPC
resource "aws_vpc" "vpc1" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "yjs-vpc1"
  }
}

# Subnet
resource "aws_subnet" "vpc1_pub_sub_az1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "yjs-vpc1-pub-az1"
  }
}

resource "aws_subnet" "vpc1_pri_sub_az1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "yjs-vpc1-pri-az1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "yjs-igw"
  }
}

# Nat Gateway
resource "aws_eip" "eip_nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  subnet_id = aws_subnet.vpc1_pub_sub_az1.id
  allocation_id = aws_eip.eip_nat.id
  tags = {
    Name = "yjs-nat"
  }
}

# Routing Table
resource "aws_route_table" "vpc1_pub_rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "yjs-vpc1-pub-rt"
  }
}

resource "aws_route_table_association" "vpc1_pub_rt_asso" {
  subnet_id      = aws_subnet.vpc1_pub_sub_az1.id
  route_table_id = aws_route_table.vpc1_pub_rt.id
}

resource "aws_route_table" "vpc1_pri_and_peering_rt" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  route {
    cidr_block = "20.0.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  }

  tags = {
    Name = "yjs-vpc1-pri-and-peering-rt"
  }
}

resource "aws_route_table_association" "vpc1_pri_and_peeing_rt_asso" {
  subnet_id      = aws_subnet.vpc1_pri_sub_az1.id
  route_table_id = aws_route_table.vpc1_pri_and_peering_rt.id
}

# Key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048  # 2048비트 RSA 키를 생성
}

resource "aws_key_pair" "key_pair" {
  key_name   = "yjs-key"
  public_key = tls_private_key.key.public_key_openssh
}

resource "local_file" "key_file" {
  filename = "./yjs-key.pem"
  content = tls_private_key.key.private_key_pem
  file_permission = "600"
}

# IAM Role + Instance Profile
resource "aws_iam_role" "ec2_role" {
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  name = "yjs-ec2-role"
}

resource "aws_iam_role_policy_attachment" "ec2_role_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "yjs-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "yjs-bastion-sg"
  vpc_id      = aws_vpc.vpc1.id
  tags = {
    Name = "yjs-bastion-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ingress_22" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = format("%s/32",trimspace(data.http.my_ip.response_body))
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_egress_all" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "ec2_sg" {
  name        = "yjs-ec2-sg"
  vpc_id      = aws_vpc.vpc1.id
  tags = {
    Name = "yjs-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_ingress_22" {
  security_group_id = aws_security_group.ec2_sg.id
  referenced_security_group_id = aws_security_group.bastion_sg.id
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "ec2_egress_all" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# Bastion
resource "aws_instance" "bastion" {
  ami           = "ami-0897f20d7e803af8f"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.vpc1_pub_sub_az1.id
  key_name = aws_key_pair.key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = "true"

  tags = {
    Name = "yjs-vp1-bastion"
  }
}


# Private Instance
resource "aws_instance" "vpc1-instance" {
  ami           = "ami-0897f20d7e803af8f"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.vpc1_pri_sub_az1.id
  key_name = aws_key_pair.key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = "false"

  tags = {
    Name = "yjs-vp1-instance"
  }
}