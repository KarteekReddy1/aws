





# #s3 bucket block
# terraform {
#   backend "s3" {
#     bucket         = "my2-terraform2-state2-${var.env}"
#     key            = "eks/dev/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-lock-${var.env}"
#     encrypt        = true
#   }
# }

#provider block

provider "aws" {
  region = var.region
}
#vpc block

resource "aws_default_vpc" "default" {
  # This will adopt existing default VPC or create it if missing
  tags = {
    Name = "default-vpc"
  }
}
#subnet block
resource "aws_default_subnet" "default" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "default-subnet"
  }
}
#EC2 instance block
resource "aws_instance" "one" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.mykey.key_name # reference the AWS key pair
  subnet_id     = aws_default_subnet.default.id
}
#key pair block
resource "aws_key_pair" "mykey" {
  key_name   = "mykey" # logical name in AWS
  public_key = file("./id_ed25519.pub")

}

#output block
output "instance_public_ip" {
  value = aws_instance.one.public_ip
}
output "vpc_id" {
  value = aws_default_vpc.default.id

}
output "instance_id" {
  value = aws_instance.one.id
}
output "aws_default_subnet" {
  value = aws_default_subnet.default.id
}   