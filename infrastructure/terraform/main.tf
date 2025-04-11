provider "aws" {
  region = "ap-northeast-1"  # 必要に応じて変更
}

# S3バケット
resource "aws_s3_bucket" "suicatest-demo_bucket" {
  bucket = "suicatest-demo-bucket-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.suicatest-demo_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lambda実行用IAMロール
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# S3にファイルを保存するLambda
resource "aws_lambda_function" "text_to_s3" {
  function_name = "TextToS3Function"
  s3_bucket     = var.code_bucket
  s3_key        = "lambda_functions/text_to_s3.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 30
  
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.suicatest-demo_bucket.id
    }
  }
}

# 1〜1000の数字を生成するLambda
resource "aws_lambda_function" "numbers_1_to_1000" {
  function_name = "Numbers1To1000Function"
  s3_bucket     = var.code_bucket
  s3_key        = "lambda_functions/numbers_1_to_1000.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 30
}

# 1001〜2000の数字を生成するLambda
resource "aws_lambda_function" "numbers_1001_to_2000" {
  function_name = "Numbers1001To2000Function"
  s3_bucket     = var.code_bucket
  s3_key        = "lambda_functions/numbers_1001_to_2000.zip"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_execution_role.arn
  timeout       = 30
}

# Step Functions実行用IAMロール
resource "aws_iam_role" "stepfunctions_execution_role" {
  name = "stepfunctions_execution_role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "stepfunctions_lambda" {
  role       = aws_iam_role.stepfunctions_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaRole"
}

# Step Functions
resource "aws_sfn_state_machine" "suicatest-demo_workflow" {
  name     = "suicatest-DemoWorkflow"
  role_arn = aws_iam_role.stepfunctions_execution_role.arn
  
  definition = <<EOF
{
  "Comment": "suicatest-Demo workflow with S3 and multiple Lambda functions",
  "StartAt": "StoreTextToS3",
  "States": {
    "StoreTextToS3": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.text_to_s3.arn}",
      "Next": "ProcessNumbersInParallel"
    },
    "ProcessNumbersInParallel": {
      "Type": "Parallel",
      "Branches": [
        {
          "StartAt": "Generate1To1000",
          "States": {
            "Generate1To1000": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.numbers_1_to_1000.arn}",
              "End": true
            }
          }
        },
        {
          "StartAt": "Generate1001To2000",
          "States": {
            "Generate1001To2000": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.numbers_1001_to_2000.arn}",
              "End": true
            }
          }
        }
      ],
      "End": true
    }
  }
}
EOF
}

data "aws_caller_identity" "current" {}

variable "code_bucket" {
  description = "S3 bucket containing Lambda function code"
  type        = string
}

output "s3_bucket_name" {
  value = aws_s3_bucket.suicatest-demo_bucket.id
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.suicatest-demo_workflow.arn
}