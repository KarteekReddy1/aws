variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "ami" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}
variable "instance_type" {
  description = "The instance type for the EC2 instance"
  type        = string
}
