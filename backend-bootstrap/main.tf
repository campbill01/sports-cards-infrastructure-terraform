terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "sports-cards"
      ManagedBy   = "terraform"
      Environment = "bootstrap"
    }
  }
}

# Provider for us-west-2 region
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "sports-cards"
      ManagedBy   = "terraform"
      Environment = "bootstrap"
    }
  }
}
