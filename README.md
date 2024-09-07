# database-terraform

Script Terraform para criação de um banco MySQL no RDS.  

No arquivo MER.md temos o diagrama de relacionamento das tabelas e documentação sobre as definições do banco de dados.

## Dependências:

### Recursos AWS:
Os seguintes componentes devem estar configurados no projeto aws:

- VPC com o nome de "techchallenge-vpc"
- Subnets privadas da VPC anterior, devidamente nomeadas como "private"
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


## Actions configuradas:
- Validate terraform files: Realiza a validação dos arquivos do terraform e checagem de formatação antes do merge das pull requests. 
- Deploy to AWS: Executa os comandos do terraform para fazer o deploy da infra no projeto autenticado. Invocado após merge com a main.
- Destroy rds database: Destrói a infra construída pelo comando de deploy. Invocado manualmente caso necessário.