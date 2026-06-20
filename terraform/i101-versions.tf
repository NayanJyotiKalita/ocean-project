terraform {
  required_version = "~> 1.15.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.47.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  profile = "default"
}

resource "random_pet" "random" {
 length = 2 
}

/*
This "random_pet" Terraform block generates a random, human-readable name consisting of two words separated by a hyphen (for example, happy-snail or swift-falcon).
Key Details
Purpose: It is used to create unique identifiers for cloud resources that require unique names, preventing naming conflicts.
Provider: It belongs to the random provider
Arguments: The length argument specifies the exact number of words to include in the generated name.
Output: You can reference the generated string in other resources using random_pet.random.id.
*/