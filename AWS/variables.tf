variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "ap-southeast-1"
}
variable "AMI" {
  default = "ami-0df7a207adb9748c7"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "./mykey.pub"
}