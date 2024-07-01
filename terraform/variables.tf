variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}
variable "subnet_cidr_block" {
  default = "10.0.10.0/24"
}
variable "avail_zone" {
  default = "us-east-2a"
}
variable "env_prefix" {
  default = "dev"
}
variable "my_ip" {
  default = "85.246.32.98/32"
}
variable "jenkins_ip" {
  default = "104.131.12.244/32"
}
variable "instance_type" {
  default = "t2.micro"
}
variable "region" {
  default = "us-east-2"
}
