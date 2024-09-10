# database-terraform

Script Terraform para criação de um banco MySQL no RDS.  

No arquivo MER.md temos o diagrama de relacionamento das tabelas e documentação sobre as definições do banco de dados.

## Dependências:

### Recursos AWS:
Os seguintes componentes devem estar configurados no projeto aws:

- VPC com o nome de "techchallenge-vpc"
- Subnets privadas da VPC anterior, devidamente nomeadas com o prefixo "private" no nome
- Cluster do EKS com nome de "techchallenge-eks-cluster"

Também utilizamos um bucket do S3 como backend do terraform para manter o estado (tfstate). Este bucket deve existir e estar acessível para que os comandos do terraform possam ser executados.  

### GitHub Action Secrets:
Os seguintes secrets devem estar configurados para que as pipelines do terraform possam ser executadas pelo github action:

- AWS_ACCESS_KEY_ID: Credencial para acesso ao projeto AWS
- AWS_SECRET_ACCESS_KEY: Credencial para acesso ao projeto AWS
- AWS_SESSION_TOKEN: Credencial para acesso ao projeto AWS
- MYSQL_USERNAME: Nome de usuário do banco MySQL 
- MYSQL_PASSWORD: Senha do banco MySQL
- TF_STATE_BUCKET: Nome do bucket onde o arquivo mysql.tfstate será armazenado

## Componentes implementados:

### mysql/security-groups.tf

Este arquivo possui a configuração das regras de segurança que permitem o tráfego de rede entre o RDS com demais componentes.

- aws_security_rule:
    - rds-eks-sg: Perímetro de segurança do RDS que possibilita a cluster EKS a se conectar à ele.
    - rds-lambda-sg: Perímetro de segurança do RDS que possibilita a Lambda de inicialização do banco a se conectar à ele.
    - lambda-rds-sg: Perímetro de segurança da Lambda que possibilita sua conexão com o RDS
- aws_security_group_rule:
    - rds-eks-sgr: Regra de ingress para comunicação do RDS com EKS.
    - rds-lambda-sgr: Regra de ingress para comunicação do RDS com a Lambda.
    - lambda-rds-sgr: Regra de egress para comunicação da Lambda com RDS.

### mysql/rds.tf

Este arquivo possui a configuração da instância RDS em si.

- aws_db_subnet_group
    - rds_subnets: Grupo de subnets privadas da VPC a ser utilizado pelo RDS. 
- aws_db_instance:
    - rds_db: Instância do RDS que hospeda o banco MySQL.

### lambda-initdb/lambda.tf

Este arquivo contém o código para deploy e execução da lambda responsável por criar as tabelas do banco.

- aws_lambda_layer_version
    - lambda_layer: Layer da lambda para instalação das dependências no ambiente.
- aws_lambda_function.
    - lambda-initdb: Lambda responsável por executar o script SQL de inicialização das tabelas do banco.

## Actions configuradas:

### validate.yaml
Validate terraform files: Realiza a validação dos arquivos do terraform e checagem de formatação antes do merge das pull requests. 

### deploy.yaml
Deploy to AWS: Executa os comandos do terraform para fazer o deploy da infra no projeto autenticado. Invocado após merge com a main.

### destroy-rds.yaml
Destroy rds database: Destrói a infra construída pelo comando de deploy. Invocado manualmente caso necessário.