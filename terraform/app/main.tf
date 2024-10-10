# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      environment     = var.environment
      owner           = "Ops"
      applicationName = var.application_name
      awsApplication  = aws_servicecatalogappregistry_application.terraform_app.application_tag.awsApplication
    }    
  }
  
  # Make it faster by skipping something
  # skip_metadata_api_check     = true
  # skip_region_validation      = true
  # skip_credentials_validation = true
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
  description = "New sample terraform application"
}