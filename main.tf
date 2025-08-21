# VPC Peering
resource "aws_vpc_peering_connection" "vpc_peering" {
  peer_region = "ap-northeast-2"
  vpc_id        = aws_vpc.vpc1.id
  peer_vpc_id   = aws_vpc.vpc2.id
  # peer_owner_id = var.peer_owner_id # VPC ID 수락자
  tags = {
    Name = "yjs-vpc-peering"
  }
  lifecycle {
    ignore_changes = [
      tags_all
    ]
  }
}

resource "aws_vpc_peering_connection_accepter" "vpc_peering_acc" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering.id
  auto_accept               = true
}

