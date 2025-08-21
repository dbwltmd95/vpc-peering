# VPC Peering

### 실습 시나리오
1. VPC 생성 
   - VPC 1: 10.0.0.0/16 
   - VPC 2: 20.0.0.0/16 
4. 생성된 각각의 VPC에 서브넷 + EC2 구축 
5. VPC 1 → VPC 2로 VPC Peering 생성 
6. 라우팅 테이블 생성 
   - VPC 1 서브넷 라우팅 테이블에 20.0.0.0/16 → Peering 연결 추가 
   - VPC 2 서브넷 라우팅 테이블에 10.0.0.0/16 → Peering 연결 추가 
9. 통신 확인
   - VPC 1의 EC2에서 VPC 2의 EC2 private IP로 ping/ssh