Project Purple Cow Definition
	
In this project we creating a python function that checks the SSL certificate expiration of a website. This application will be deployed using AWS Lambda serverelss and API Gateway for invocation.

Prerequisites

1. Terraform CLI
2. An AWS Account
3. AWS CLI installed and configured
4. Python3 installed
5. Pip installed
6. PyOpenSSL package

Create Python Function

We begin by creating a python function that makes use of OpenSSL to check the certificate expiration date for a website.
We then package the funciton in an archive, this is necessary to deploy the function to AWS Lambda. This can be seen in the archive file data block in the main.tf file
Then you must make sure to add the aws provider and archive provider to your provider.tf file. Add your AWS account crendentials to the provider.tf file as well.

Create Lambda Function in Terraform

To create and deploy our python function using AWS Lambda, we must deploy the archive file to an S3 bucket. So we create resource blocks for our s3 bucket and object and then secure our bucket using the bucket public access block. We must also create an IAM role with basic lambda execution policies, this can be seen in the iam role resource block and the role policy attachment resource block. Now finally we can create our lambda funciton resource block, we make use of a reference expression to define the bucket and key attribut in the lambda function block. I have made the assumption that we want to store logs from the Lambda function and have thus created a cloud watch log group that stores the logs for 14 days.

Create an HTTP API using API Gateway

Here we create the HTTP API using apigateway block and then define the stage. The stage can be dev, test, prod, etc. Here we call it lambda stage. We then define the apigateway integration which connects the API gateway to the Lmabda function, then the API gateway route which maps the HTTP request to the Lambda function, then the lambda permission block gives the API gateway permission to invoke the Lambda function. And I assume that the client wants to store logs so I created a cloudwatch log group. Add an output.tf file that outputs the value of the url used to invoke the Lambda function.

Terraform workflow

Run:

terraform init

terraform plan

terraform apply then enter yes when prompted.

to test your lambda function run: 

	curl "$(terraform output -raw base_url)/main"



When done input terraform destroy and enter yes when prompted



