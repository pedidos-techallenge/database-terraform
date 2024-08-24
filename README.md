# database-terraform

Script Terraform para criação de um banco mysql no RDS.  
Credenciais para acesso no AWS são armazenadas nos secrets do GH Actions.  
Utilizamos um bucket do S3 como backend do terraform para manter o estado (tfstate). Este bucket deve existir e estar acessível
para que os comandos do terraform possam ser executados.  

O comando `terraform init` deve ser executado antes da pull request para setup inicial
```
terraform init \
    -backend-config="bucket=${TF_STATE_BUCKET}" \
    -backend-config="key=mysql.tfstate" \
    -backend-config="region=us-east-1"
```

## GH Secrets utilizados:
- AWS_ACCESS_KEY_ID: Credencial para acesso ao projeto AWS
- AWS_SECRET_ACCESS_KEY: Credencial para acesso ao projeto AWS
- AWS_SESSION_TOKEN: Credencial para acesso ao projeto AWS
- MYSQL_USERNAME: Nome de usuário do banco MySQL 
- MYSQL_PASSWORD: Senha do banco MySQL
- TF_STATE_BUCKET: Nome do bucket onde o arquivo mysql.tfstate será armazenado

## GH Actions disponíveis:
- `terraform validate` é executado em pull requests, confirme que a validação está correta antes de aprovar o merge
- `terraform apply` executado imediatamente no merge da main
- `terraform destroy` está disponível para execução manual
