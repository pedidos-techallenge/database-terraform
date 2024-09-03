terraform {
  backend "s3" {}
}

provider "aws" {}

# TODO: create a resource for retrieving password from secret manager

# Referencing project's vpc to use on other resources
data "aws_vpc" "techchallenge-vpc" {
  filter {
    name = "tag:Name"
    values = ["techchallenge-vpc"]
  }
}

# Referencing private subnets
data "aws_subnets" "private-subnets" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.techchallenge-vpc.id]
  }

  filter {
    name = "tag:Name"
    values = ["*private*"]
  }
}

# RDS subnets must be in a sg group
resource "aws_db_subnet_group" "rds_subnets" {
  name = "rds_subnets"
  subnet_ids = data.aws_subnets.private-subnets.ids
}

# Creating RDS instance
resource "aws_db_instance" "test_mysql" {
  engine              = "mysql"
  identifier          = "test-mysql"
  allocated_storage   = 20
  engine_version      = "8.0.35"
  instance_class      = "db.t3.small"
  username            = var.MYSQL_USERNAME
  password            = var.MYSQL_PASSWORD
  skip_final_snapshot = true
  publicly_accessible = false
  multi_az            = false
  db_name             = "test_db"
  port                = 3306
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}


# Referencing eks cluster
data "aws_eks_cluster" "techchallenge-eks-cluster" {
  name = "techchallenge-eks-cluster"
}

# Security group for tunneling communication from EKS to RDS
resource "aws_security_group" "rds_sg" {
  name   = "rds_sg"
  vpc_id = data.aws_vpc.techchallenge-vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_eks_cluster.techchallenge-eks-cluster.vpc_config[0].cluster_security_group_id]
  }

  # TODO: Make more restrictive
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}