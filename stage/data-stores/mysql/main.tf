provider "aws" {
  region = "ap-northeast-2"
}

terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-qazz92"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"
    encrypt = true

    dynamodb_table = "terraform-up-and-running-lock"
  }
}

resource "aws_db_instance" "example" {
  instance_class = "db.t2.micro"
  engine = "mysql"
  allocated_storage = 10
  name = "example_database"
  username = "admin"
  password = var.db_password
  skip_final_snapshot = true
}