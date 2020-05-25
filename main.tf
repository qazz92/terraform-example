provider "aws" {
  region = "ap-northeast-2"
}

resource "aws_instance" "example" {
  ami = "ami-00edfb46b107f643c"
  instance_type = "t3a.micro"

  tags = {
    Name = "terraform-example"
  }
}