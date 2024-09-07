# TODO: Maybe separate in another module so we can destroy the lambda function after the database is created
# There's a bug when deleting security groups, AWS takes a up to 20 min to delete the network interfaces associated with the security group after 
# lambda's deletion. This causes the deletion of the security group to fail. Maybe we can delete just the lambda, leave the networking stuff?
terraform {
  # backend "s3" {}
}

data "aws_iam_role" "lab-role" {
  name = "LabRole"
}

resource "null_resource" "install_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r initdb/layer/requirements.txt -t initdb/layer/python/lib/python3.9/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}


data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "initdb/layer"
  output_path = "layer.zip"
  depends_on = [
    null_resource.install_layer_dependencies
  ]
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename = data.archive_file.layer_zip.output_path
  source_code_hash = data.archive_file.layer_zip.output_base64sha256
  layer_name = "python-requirements"
  compatible_runtimes = [ "python3.9" ]
  depends_on = [ data.archive_file.layer_zip ]
}

data archive_file "lambda_zip" {
  type        = "zip"
  source_dir  = "initdb/function"
  output_path = "lambda_function.py.zip"
}


# Security group for tunneling communication from Lambda to RDS
resource "aws_security_group" "rds-lambda-sg" {
  name   = "rds-lambda-sg"
  vpc_id = data.aws_vpc.techchallenge-vpc.id
}

resource "aws_security_group" "lambda-rds-sg" {
  name   = "lambda-rds-sg"
  vpc_id = data.aws_vpc.techchallenge-vpc.id
}

resource "aws_security_group_rule" "rds-lambda-sgr" {
  type = "ingress"
  from_port = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_group_id = aws_security_group.rds-lambda-sg.id
  source_security_group_id = aws_security_group.lambda-rds-sg.id
  depends_on = [ aws_security_group.lambda-rds-sg ]
}

resource "aws_security_group_rule" "lambda-rds-sgr" {
  type = "egress"
  from_port = 3306
  to_port         = 3306
  protocol        = "tcp"
  security_group_id = aws_security_group.lambda-rds-sg.id
  source_security_group_id = aws_security_group.rds-lambda-sg.id
  depends_on = [ aws_security_group.rds-lambda-sg ]
}


resource "aws_lambda_function" "rds_sql_lambda" {
  function_name = "init-rds"
  description = "Lambda function to initialize RDS"
  role          = data.aws_iam_role.lab-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  
  filename      = data.archive_file.lambda_zip.output_path

  layers = [aws_lambda_layer_version.lambda_layer.arn] 
  depends_on = [
    data.archive_file.lambda_zip,
    aws_lambda_layer_version.lambda_layer,
    aws_db_instance.rds_db
  ]

  timeout = 600

  vpc_config {
    subnet_ids         = data.aws_subnets.private-subnets.ids
    security_group_ids = [aws_security_group.lambda-rds-sg.id]
  }
  
  environment {
    variables = {
      DB_CLUSTER_ARN = aws_db_instance.rds_db.arn
      DB_HOST     = aws_db_instance.rds_db.address
      DB_PORT     = aws_db_instance.rds_db.port
      DB_USER     = var.MYSQL_USERNAME
      DB_PASSWORD = var.MYSQL_PASSWORD
      DB_NAME     = aws_db_instance.rds_db.db_name
    }
  }

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# Lambda invocation to initialize the RDS database
# The resource for this module only triggers the once upon deployment. After that the function may be invoked manually
resource "aws_lambda_invocation" "init_db" {
  function_name = aws_lambda_function.rds_sql_lambda.function_name
  input = jsonencode({
    "operation": "init_db"
  })

  depends_on = [
    aws_lambda_function.rds_sql_lambda,
    aws_db_instance.rds_db,
    aws_security_group.rds-lambda-sg,
    aws_security_group.lambda-rds-sg,
    aws_security_group_rule.rds-lambda-sgr,
    aws_security_group_rule.lambda-rds-sgr,
  ]
}

output "result_entry" {
  value = aws_lambda_invocation.init_db.result
}