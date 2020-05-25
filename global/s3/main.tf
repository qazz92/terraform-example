provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-qazz92"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true

    dynamodb_table = "terraform-up-and-running-lock"
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-qazz92"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  hash_key = "LockID"
  name = "terraform-up-and-running-lock"
  read_capacity = 2
  write_capacity = 2

  attribute {
    name = "LockID"
    type = "S"
  }
}