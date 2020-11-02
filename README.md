# Riiid-HackerNews

The project takes one parameter *h* representing the number of hours and returns the deepest thread from [hackernews](https://news.ycombinator.com/), which happened within *h* hours.

## How to run code locally

Before testing code on a local machine, you need `python 3.7`, `git`, `virtualenv`, and `pip` installed on the computer. Use the below command to verify.

```
$ python --version
Python 3.7.9
$ git --version
git version 2.24.3
$ virtualenv --version
16.4.1
$ pip --version
pip 20.2.4 PATH/TO/PIP (python 3.7)
```

- Use `git` to checkout the repository.
```
git clone git@github.com:Bumblebeeee/riiid-hackernews.git
```

- Go to the project folder, create and activate python environment
```
$ cd riiid-hackernews && virtualenv env/
$ source env/bin/activate
```

- Install the required packages
```
(env)$ [ -d "python" ] && rm -rf python/; mkdir python && pip install -r function/requirements.txt
```

- Go to the function folder, pass the parameter and execute hn.py
```
$ cd function 
$ python hn.py 1
``` 

## How to deploy

### Prerequisite

#### Tools

Before the deployment, ensure the [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html),  [terraform 0.13.4](https://releases.hashicorp.com/terraform/0.13.4/) ([Windows](https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_windows_amd64.zip), [Linux](https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_linux_amd64.zip)) installed. And use below command to verify.
```
$ aws --version
aws-cli/1.18.157 Python/3.7.9 Darwin/19.6.0 botocore/1.19.4

$ terraform --version
Terraform v0.13.4
```

Besides the tools, you also need 3 AWS accounts for the deployment:

- S3 backend for Terraform
- Test environment account
- Prod environment account

Generate and download credentials for above 3 AWS account, make sure each account has programmatic access(see [Understanding and getting your AWS credentials](https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html) for details)

#### Setup AWS Credentials

- Backup local AWS Configurations
```
$ cp -R ~/.aws ~/.aws.backup
```

- Setup AWS Configuration for the project
```
$ aws configure set aws_access_key_id S3_BACKEND_ACCESS_KEY_ID
$ aws configure set aws_secret_access_key S3_BACKEND_SECRET_ACCESS_KEY
$ aws configure set aws_access_key_id DEV_ACCESS_KEY_ID --profile dev
$ aws configure set aws_secret_access_key DEV_SECRET_ACCESS_KEY --profile dev
$ aws configure set aws_access_key_id PROD_ACCESS_KEY_ID --profile prod 
$ aws configure set aws_secret_access_key PROD_SECRET_ACCESS_KEY --profile prod
```

#### Create S3 bucket for terraform backend

```
aws s3api create-bucket --bucket riiid-hackernews --region us-east-1
```

### Deploy to DEV Target

Assume you have tested code on the local machine, and you are in the root of the project folder
```
$ tree -L 1
.
├── Jenkinsfile
├── README.md
├── build.dockerfile
├── function
├── python
├── terraform
└── terraform.tfstate

```

1. Pack function code and lambda layer
```
$ zip -j function.zip $(ls -d function/*)
$ zip -r riiid_hacknews_runtime.zip python/*
```

2. Setup terraform `dev` workspace
```
$ cd terraform
$ terraform init
$ terraform workspace new dev
$ terraform workspace select dev(if dev workspace exists)
```

3. Create infrastructure and Deploy project
```
$ terraform plan --out=plan.txt --var env=dev
```
Verify `plan.txt` and deploy project
```
$ terraform apply "plan.txt"
```

4. Verify the deployment
```
$ aws --profile dev lambda invoke --region us-east-1 --function-name riiid_hackernews_lambda output.txt --payload '{"h":0.02}' 
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
```

### Deploy to PROD Target

Assume you have tested code on the local machine, and you are in the root of the project folder
```
$ tree -L 1
.
├── Jenkinsfile
├── README.md
├── build.dockerfile
├── function
├── python
├── terraform
└── terraform.tfstate

```

1. Pack function code and lambda layer(skip this step if code and layer have been packed already)
```
$ zip -j function.zip $(ls -d function/*)
$ zip -r riiid_hacknews_runtime.zip python/*
```

2. Setup terraform `prod` workspace
```
$ cd terraform
$ terraform init
$ terraform workspace new prod
$ terraform workspace select prod(if prod workspace exists)
```

3. Create infrastructure and Deploy project
```
$ terraform plan --out=plan.txt --var env=prod
```
Verify `plan.txt` and deploy project
```
$ terraform apply "plan.txt"
```

4. Verify the deployment
```
$ aws --profile prod lambda invoke --region us-east-1 --function-name riiid_hackernews_lambda output.txt --payload '{"h":0.02}' 
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
```

## Cleanup

Assume you are in the root of the project folder
```
$ tree -L 1
.
├── Jenkinsfile
├── README.md
├── build.dockerfile
├── function
├── python
├── terraform
└── terraform.tfstate

```
Go to `terraform` folder and switch to `dev` workspace
```
$ cd terraform
$ terraform workspace select dev
```

Execute `terraform destroy`, verify output, and type `yes`

```
$ terraform destroy

*** truncate output ***
Changes to Outputs:

Do you really want to destroy all resources in workspace "dev"?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes
```