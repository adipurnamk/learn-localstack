provider "aws" {  
  region                      = "us-east-1"  
  access_key                  = "test"  
  secret_key                  = "test"  
  skip_region_validation      = true  
  skip_credentials_validation  = true  
}  

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tf-state-bucket"
  acl    = "private"

  versioning {
    enabled = true
  }
}
