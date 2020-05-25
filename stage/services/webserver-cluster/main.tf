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

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = "terraform-up-and-running-state-qazz92"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

data "template_file" "user_data" {
  template = file("user_data.sh")

  vars = {
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }
}

data "aws_availability_zones" "all" {}

resource "aws_launch_configuration" "example" {
  image_id = "ami-00edfb46b107f643c"
  instance_type = "t3a.micro"
  security_groups = [aws_security_group.instance.id]

  user_data = data.template_file.user_data.rendered

  lifecycle {
    create_before_destroy = true
  }
}

//resource "aws_instance" "example" {
//  ami = "ami-00edfb46b107f643c"
//  instance_type = "t3a.micro"
//  vpc_security_group_ids = [aws_security_group.instance.id]
//
//  user_data = <<-EOF
//            #!/bin/bash
//            echo "Hello, World!" > index.html
//            nohup busybox httpd -f -p "${var.server_port}" index.html &
//            EOF
//
//  tags = {
//    Name = "terraform-example"
//  }
//}

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    from_port = var.server_port
    protocol = "tcp"
    to_port = var.server_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  max_size = 10
  min_size = 2

  availability_zones = data.aws_availability_zones.all.names
  launch_configuration = aws_launch_configuration.example.id

  load_balancers = [aws_elb.example.name]
  health_check_type = "ELB"

  tag {
    key = "Name"
    propagate_at_launch = true
    value = "terraform-asg-example"
  }
}

resource "aws_elb" "example" {

  name = "terraform-asg-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups = [aws_security_group.elb.id]

  health_check {
    healthy_threshold = 2
    interval = 5
    target = "HTTP:${var.server_port}/"
    timeout = 3
    unhealthy_threshold = 2
  }

  listener {
    instance_port = var.server_port
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-example-elb"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}