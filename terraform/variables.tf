variable "region" {
  default = "ap-south-1"
}

variable "ami_id" {
  # Ubuntu 22.04 LTS in Mumbai (ap-south-1)
  default = "ami-0f58b397bc5c1f2e8"
}

variable "key_name" {
  description = "Name of your AWS key pair for SSH access"
}