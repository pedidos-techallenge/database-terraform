
# Packaging pymysql dependencies in a Lambda Layer
resource "null_resource" "install_layer_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r layer/requirements.txt -t layer/python/lib/python3.9/site-packages"
  }
  triggers = {
    trigger = timestamp()
  }
}

data "archive_file" "layer_zip" {
  type        = "zip"
  source_dir  = "layer"
  output_path = "layer.zip"
  depends_on = [
    null_resource.install_layer_dependencies
  ]
}

# Ziping the Lambda's function code
resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = data.archive_file.layer_zip.output_path
  source_code_hash    = data.archive_file.layer_zip.output_base64sha256
  layer_name          = "python-requirements"
  compatible_runtimes = ["python3.9"]
  depends_on          = [data.archive_file.layer_zip]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "function"
  output_path = "lambda_function.py.zip"
}


# Deploying the Lambda function
resource "aws_lambda_function" "rds_sql_lambda" {
  function_name = "initdb"
  description   = "Lambda function to initialize RDS"
  role          = data.aws_iam_role.lab-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename = data.archive_file.lambda_zip.output_path

  layers = [aws_lambda_layer_version.lambda_layer.arn]
  depends_on = [
    data.archive_file.lambda_zip,
    aws_lambda_layer_version.lambda_layer
  ]

  timeout = 600

  vpc_config {
    subnet_ids         = data.aws_subnets.private-subnets.ids
    security_group_ids = [data.aws_security_group.lambda-rds-sg.id]
  }

  environment {
    variables = {
      DB_CLUSTER_ARN = data.aws_db_instance.rds_db.db_instance_arn
      DB_HOST        = data.aws_db_instance.rds_db.address
      DB_PORT        = data.aws_db_instance.rds_db.port
      DB_USER        = var.MYSQL_USERNAME
      DB_PASSWORD    = var.MYSQL_PASSWORD
      DB_NAME        = data.aws_db_instance.rds_db.db_name
    }
  }

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# Invoking the Lambda function to initialize the RDS
# The resource for this module only triggers the once upon deployment. After that the function may be invoked manually
resource "aws_lambda_invocation" "invoke_init_db" {
  function_name = aws_lambda_function.rds_sql_lambda.function_name
  input = jsonencode({
    "operation" : "invoke_init_db"
  })

  depends_on = [
    aws_lambda_function.rds_sql_lambda
  ]
}

output "result_output" {
  value = aws_lambda_invocation.invoke_init_db.result
}