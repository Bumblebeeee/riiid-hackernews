FROM python:3.7

ARG S3_BACKEND_SECRET_ACCESS_KEY
ARG S3_BACKEND_ACCESS_KEY_ID
ARG DEV_SECRET_ACCESS_KEY
ARG DEV_ACCESS_KEY_ID
ARG PROD_ACCESS_KEY_ID
ARG PROD_SECRET_ACCESS_KEY

RUN apt-get update && \
    apt-get install -yq --no-install-recommends zip virtualenv && \
    apt-get clean && \
    wget https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_linux_amd64.zip && \
    unzip terraform_0.13.4_linux_amd64.zip -d /usr/bin && \
    pip install -I --no-cache-dir awscli==1.18 && \
    aws configure set aws_access_key_id ${S3_BACKEND_ACCESS_KEY_ID} && \
    aws configure set aws_secret_access_key ${S3_BACKEND_SECRET_ACCESS_KEY} && \
    aws configure set aws_access_key_id ${DEV_ACCESS_KEY_ID} --profile dev && \
    aws configure set aws_secret_access_key ${DEV_SECRET_ACCESS_KEY} --profile dev && \
    aws configure set aws_access_key_id ${PROD_ACCESS_KEY_ID} --profile prod && \
    aws configure set aws_secret_access_key ${PROD_SECRET_ACCESS_KEY} --profile prod
