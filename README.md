# sds-terraform

to prepare resource run this script (for m1 user, you need to install template file package helper due to package unavailable: https://discuss.hashicorp.com/t/template-v2-2-0-does-not-have-a-package-available-mac-m1/35099/3)

`terraform init` 

---

config `terraform.tfvars` file for some setting

```
region            = "" # vpc region
availability_zone = "" # instance availability zone
ami               = "" # instance image id
bucket_name       = "" # s3 bucket name
database_name     = "" # wordpress database name
database_user     = "" # wordpress database user
database_pass     = "" # wordpress database password
admin_user        = "" # wordpress admin account username
admin_pass        = "" # wordpress admin account password
```
---

to initialize wordpress with s3 and infrastructure run this script

`terraform apply`

note that you have ~/.aws/credentials for iam user which have full access for ec2, s3 and iam user

---
