variable "aws_region" {   # variabalized this argument to dynamically provision the infra in another EU region if and when needed
  description = "The region in which the resources are going to get provisioned"
  type = string
}

# Environment Variable
variable "environment" {
  description = "Environment variable to be used a prefix"
  type = string
  default = "dev"
}
