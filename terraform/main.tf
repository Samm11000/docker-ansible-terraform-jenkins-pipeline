# Tell Terraform to use AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # Remote state — keeps state safe in S3 (set up S3 bucket first)
  backend "s3" {
  bucket = "swyam-devops-tfstate-2026"
  key    = "prod/terraform.tfstate"   # ✅ correct
  region = "us-east-1"
}
}

provider "aws" {
  region = var.region
}

# Security Group — controls what traffic is allowed
resource "aws_security_group" "devops_sg" {
  name = "devops-security-group"

  # Allow SSH from your IP only (replace with your IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTP traffic
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Jenkins port
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
  from_port   = 3000
  to_port     = 3000
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
}

# App Server EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"    
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = {
    Name = "app-server"
  }
}

# Jenkins Server EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = {
    Name = "jenkins-server"
  }
}