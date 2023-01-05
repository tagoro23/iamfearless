data "archive_file" "python_zip"{
    type         = "zip"
    source_dir   = "${path.module}/python/"
    output_path  = "${path.module}/python/main.zip"

}

resource "aws_iam_role" "lambda_role"{
    name                = fearless_role
    assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement":[
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


resource "aws_iam_role_policy_attachment" "lambda_policy"{
    role        = aws_iam_role.lambda_role.name
    policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}


resource "aws_s3_bucket" "lambda_bucket" {
    bucket        = "temitope1_4_2023_bucket"
    force_destroy = true
}


resource "aws_s3_bucket_public_access_block" "lambda_bucket{
    bucket = aws_s3_bucket.lambda_bucket.id

    block_public_acls        = true 
    block_public_policy      = true 
    ignore_public_acls       = true
    restrict_public_buckets  = true
}

resource "aws_s3_object" "lambda_object"{
    bucket      = aws_s3_object.lambda_bucket.id
    key         = "python.zip"
    source      = data.archive_file.python_zip.output_path
    source_hash = filemd5(data.archive_file.python_zip.output_path)
    
}

resource "aws_lambda_function" "terraform_lambda_function"{
    function_name    = "Expiration_lambda"

    s3_bucket        = aws_s3_bucket.lambda_bucket.id
    s3_key           = aws_s3_object.lambda_object.key

    runtime          = "python3.8"
    handler          = "main.GetExpiration"
    role             = aws_iam_role.lambda_role.arn
    source_code_hash = data.archive_file.python_zip.output_base64sha256

}

resource "aws_cloudwatch_log_group" "lambda_group"{
    name               = "/aws/lambda/${aws_lambda_function.terraform_lambda_function.function_name}"
    retention_in_days  = 14
}

resource "aws_apigatewayv2_api" "lambda" {
    name          = "serveless_lambda_gw"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda"{
    api_id       = aws_apigatewayv2_api.lambda.id
    name         = "lambda_stage"
    auto_deploy  =  true
    access_log_settings{
        destination_arn = aws_cloudwatch_log_group.api_gw.arn

        format = jsonencode({
            requestId               = "$context.requestId"
            sourceIp                = "$context.identity.sourceIp"
            requestTime             = "$context.requestTime"
            protocol                = "$context.protocol"
            httpMethod              = "$context.httpMethod"
            resourcePath            = "$context.resourcePath"
            routeKey                = "$context.routeKey"
            status                  = "$context.status"
            responseLength          = "$context.responseLength"
            integrationErrorMessage = "$context.integrationErrorMessage"
        }
      )
    }
}

resource "aws_apigatewayv2_integration" "lambda"{
    api_id              = aws_apigatewayv2_api.lambda.id
    integration_uri     = aws_lambda_function.terraform_lambda_function.invoke_arn
    integration_type    = "AWS_PROXY"
    integration_method  = "POST"
}

resource "aws_apigatewayv2_api" "lambda_route" {
    api_id     = aws_apigatewayv2_api.lambda.id 
    route_key  = "GET /main"
    target     = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
    name               = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
    retention_in_days  = 30
}

resource "aws_lambda_permission" "api_gw"{
    statement_id   = "AllowExecutionFromAPIGateway"
    action         = "lambda:InvokeFunction"
    function_name  = aws_lambda_function.terraform_lambda_function.function_name
    principal      = "apigateway.amazonaws.com"
    source_arn     = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
