# terraform-cs

## Put your aws secret key and access id in the provider.tf file 
## install terraform
## locate the directory && get inside it
## run terraform init
## run terraform apply --auto-approve

### this script will deploy 2 instances
### each of the instance will have different webservers
### NGINX in us-east-1b
### APACHE in us-east-1a
### application loadbalacer
### instances are ubuntu server t3.micro and have 1gb of ebs attached
### index.html can be located in /webroot/html
