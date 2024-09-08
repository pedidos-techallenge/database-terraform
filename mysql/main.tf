terraform {
  backend "s3" {}
}

provider "aws" {}

### General data sources
data "aws_vpc" "techchallenge-vpc" {
  filter {
    name   = "tag:Name"
    values = ["techchallenge-vpc"]
  }
}