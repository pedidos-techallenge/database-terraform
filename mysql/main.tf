terraform {
  backend "s3" {
    bucket = "techchallangebucket"    
    region = "us-east-1"
    key    = "mysql.tfstate"
  }
}

provider "aws" {}

### General data sources
data "aws_vpc" "techchallenge-vpc" {
  filter {
    name   = "tag:Name"
    values = ["techchallenge-vpc"]
  }
}