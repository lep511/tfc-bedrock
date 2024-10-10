# Configure Terraform Cloud
terraform { 
  cloud { 
    
    organization = "aws-workshop-lep511" 

    workspaces { 
      name = "terraform-bedrock" 
    } 
  } 
}