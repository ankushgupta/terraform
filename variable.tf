variable "count" {
    default = 1
  }
variable "region" {
  description = "AWS region for hosting our your network"
  default = "ap-south-1"
}
variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to add to AWS."
  default = "/tmp/ec2.pem"
}
variable "key_name" {
  description = "Key name for SSHing into EC2"
  default = "ec2"
}
variable "amis" {
  description = "Base AMI to launch the instances"
  default = {
  ap-south-1 = "ami-8da8d2e2"
  }
}
