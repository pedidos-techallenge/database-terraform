provider "aws" {}

# TODO: create a resource for retrieving password from secret manager

resource "aws_db_instance" "test_mysql" {
    engine = "mysql"
    identifier = "test-mysql"
    allocated_storage = 20
    engine_version = "8.0.35"
    instance_class = "db.t3.small"
    username = "admin"
    password = "<placeholder>"
    skip_final_snapshot = true
    publicly_accessible = false
    multi_az = false
    db_name = "test_db"
    port = 3306
}