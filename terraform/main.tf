# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      env             = var.environment
      owner           = "Ops"
      applicationName = var.application_name
      awsApplication  = aws_servicecatalogappregistry_application.terraform_app.application_tag.awsApplication
      version         = var.version_app
      service         = var.application_name
    }    
  }
  
  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}

# Create application using aliased 'application' provider
provider "aws" {
  alias = "application"
  region = var.aws_region
}

# Register new application
# An AWS Service Catalog AppRegistry Application is displayed in the AWS Console under "MyApplications".
resource "aws_servicecatalogappregistry_application" "terraform_app" {
  provider    = aws.application
  name        = var.application_name
  description = "Bedrock & Rust - Terraform application"
}


##################
# Lambda [Rust]
##################
module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "${var.environment}-bedrock-function"
  description   = "Sample function of Bedrock in Rust"
  runtime       = "provided.al2023"
  architectures = ["x86_64"]
  handler       = "bootstrap"
  timeout       = 30
  
  create_package         = false
  local_existing_package = "bootstrap.zip"

  attach_policy_json = true
  policy_json        = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
          {
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel",
                "bedrock:InvokeModelWithResponseStream",
                "bedrock:GetFoundationModel",
                "bedrock:ListFoundationModels",
                "bedrock:GetFoundationModelAvailability"
            ],
            "Resource": "*"
          }
      ]
    }
  EOT

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.apigateway_v2.api_execution_arn}/*/*"
      resource_path = "/invokemodel"
    }
  }
}

##################
# Extra resources
##################

module "apigateway_v2" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"

  name          = "${var.environment}-bedrock-api"
  description   = "Bedrock HTTP API Gateway"
  protocol_type = "HTTP"

  create_domain_name = false
  create_domain_records = false

  routes = {
    "POST /invokemodel" = {
      authorization_type   = "NONE"
      integration = {
        uri                    = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }
    }
  }
}
