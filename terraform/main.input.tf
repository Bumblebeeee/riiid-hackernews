variable "region" {
  default = "us-east-1"
}
variable "env" {
  default = "dev"
}
variable "profiles" {
  type = map(any)
  default = {
    "dev"  = "dev"
    "prod" = "prod"
  }
}

variable "if_publish" {
  type = bool
}
