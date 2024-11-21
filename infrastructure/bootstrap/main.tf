provider "aws" {  
  region                      = "us-east-1"  
  access_key                  = "test"  
  secret_key                  = "test"  
  skip_region_validation      = true  
  skip_credentials_validation  = true  
  endpoints {   
    s3          = "http://localhost:4566"  
  }  
}  

resource "aws_s3_bucket" "terraform_state" {
  bucket = "localstack-tf-state-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}
