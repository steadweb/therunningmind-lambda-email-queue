provider "aws" {
  region = "eu-west-2"
}

terraform {
  backend "s3" {
    encrypt        = true
    region         = "eu-west-2"
    bucket         = "happypeoplecompany-state-storage"
    dynamodb_table = "happypeoplecompany-state-lock"
    key            = "email-lambda.tfstate"
  }
}

resource "aws_sqs_queue" "email" {
  name = "email"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email-dl.arn
    maxReceiveCount     = 3
  })

  tags = {
    Environment = "production"
  }
}

resource "aws_sqs_queue" "email-dl" {
  name = "email-dl"
}

data "archive_file" "email-lambda" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/email.js.zip"
}

resource "aws_lambda_function" "email-lambda" {
  function_name = "email"
  handler       = "index.ses"
  role          = aws_iam_role.email-lambda.arn
  runtime       = "nodejs12.x"

  filename         = data.archive_file.email-lambda.output_path
  source_code_hash = data.archive_file.email-lambda.output_base64sha256

  timeout     = 30
  memory_size = 128
}

resource "aws_lambda_event_source_mapping" "email-lambda" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.email.arn
  enabled          = true
  function_name    = aws_lambda_function.email-lambda.arn
}

resource "aws_iam_role" "email-lambda" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "email-lambda" {
  policy_arn = aws_iam_policy.email-lambda.arn
  role       = aws_iam_role.email-lambda.name
}

resource "aws_iam_policy" "email-lambda" {
  policy = data.aws_iam_policy_document.email-lambda.json
}

data "aws_iam_policy_document" "email-lambda" {
  statement {
    sid       = "AllowSQSPermissions"
    effect    = "Allow"
    resources = ["arn:aws:sqs:*"]

    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
  }

  statement {
    sid       = "AllowInvokingLambdas"
    effect    = "Allow"
    resources = ["arn:aws:lambda:eu-west-2:*:function:*"]
    actions   = ["lambda:InvokeFunction"]
  }

  statement {
    sid       = "AllowCreatingLogGroups"
    effect    = "Allow"
    resources = ["arn:aws:logs:eu-west-2:*:*"]
    actions   = ["logs:CreateLogGroup"]
  }

  statement {
    sid       = "AllowWritingLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:eu-west-2:*:log-group:/aws/lambda/*:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid       = "AllowSendTemplatedEmail"
    effect    = "Allow"
    resources = ["arn:aws:ses:eu-west-1:691650502751:*"]

    actions = [
      "ses:SendTemplatedEmail"
    ]
  }
}
