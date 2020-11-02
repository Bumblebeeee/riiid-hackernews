terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
  backend "s3" {
    bucket = "riiid-hackernews"
    key    = "riiid-hackernews.tfstate"
    region = "us-east-1"
  }
}
provider "aws" {
  profile = var.profiles[var.env]
  region  = var.region
}

resource "aws_lambda_function" "riiid_hackernews_lambda" {
  function_name    = "riiid_hackernews_lambda"
  handler          = "hn.lambda_handler"
  filename         = "../function.zip"
  role             = aws_iam_role.role_lambda_exec.arn
  source_code_hash = filebase64sha256("../function.zip")

  runtime     = "python3.7"
  timeout     = 900
  memory_size = 256
  description = ""
  layers      = [aws_lambda_layer_version.riiid_hackernews_layer.arn]
  depends_on = [
    aws_iam_role_policy_attachment.riiid_hackernews_lambda_logs,
    aws_cloudwatch_log_group.riiid_hackernews_lambda_log_group,
  ]
}

resource "aws_lambda_layer_version" "riiid_hackernews_layer" {
  filename            = "../riiid_hacknews_runtime.zip"
  layer_name          = "riiid_hacknews_runtime"
  source_code_hash    = filebase64sha256("../riiid_hacknews_runtime.zip")
  compatible_runtimes = ["python3.7"]
}

resource "aws_iam_role" "role_lambda_exec" {
  name               = "role_lambda_exe"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "Policy for lambda function logging"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "riiid_hackernews_lambda_log_group" {
  name              = "/aws/lambda/riiid_hackernews_lambda"
  retention_in_days = 5
}
resource "aws_iam_role_policy_attachment" "riiid_hackernews_lambda_logs" {
  role       = aws_iam_role.role_lambda_exec.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}


#resource "aws_api_gateway_rest_api" "riiid_hackernews_gateway" {
#  name = "riiid_hackernews_gateway"
#}
