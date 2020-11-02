variable "region" {
  default = "us-east-1"
}
variable "env" {
  default = "dev"
}
variable "profiles" {
  type = map
  default = {
    "dev"  = "dev"
    "prod" = "prod"
  }
}
