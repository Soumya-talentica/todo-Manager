Configure AWS credentials:
    aws configure

Set up Terraform Variables:
    cd infra/terraform
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with your values

Deploy Infra:
    terraform init
    terraform plan
    terraform apply

Deploy Applications:
   cd ../scripts
   chmod +x *.sh
   ./deploy.sh