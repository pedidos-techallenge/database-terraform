# Setting up Security groups for allowing communication between RDS, EKS and Lambda

### EKS Security Group
# Referencing eks cluster
data "aws_eks_cluster" "techchallenge-eks-cluster" {
  name = "techchallenge-eks-cluster"
}

# Security group for RDS
resource "aws_security_group" "rds-eks-sg" {
  name   = "rds-eks-sg"
  vpc_id = data.aws_vpc.techchallenge-vpc.id
}

# Security group rule, RDS -> EKS
resource "aws_security_group_rule" "rds-eks-sgr" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds-eks-sg.id
  source_security_group_id = data.aws_eks_cluster.techchallenge-eks-cluster.vpc_config[0].cluster_security_group_id
}

### Lambda (initdb) Security Group
# Security group for tunneling communication from Lambda to RDS
resource "aws_security_group" "rds-lambda-sg" {
  name   = "rds-lambda-sg"
  vpc_id = data.aws_vpc.techchallenge-vpc.id
}

resource "aws_security_group" "lambda-rds-sg" {
  name   = "lambda-rds-sg"
  vpc_id = data.aws_vpc.techchallenge-vpc.id
}

# Security group rules, RDS -> Lambda
resource "aws_security_group_rule" "rds-lambda-sgr" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds-lambda-sg.id
  source_security_group_id = aws_security_group.lambda-rds-sg.id
  depends_on               = [aws_security_group.lambda-rds-sg]
}

# RDS <- Lambda
resource "aws_security_group_rule" "lambda-rds-sgr" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda-rds-sg.id
  source_security_group_id = aws_security_group.rds-lambda-sg.id
  depends_on               = [aws_security_group.rds-lambda-sg]
}
