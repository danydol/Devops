terraform {
  required_version = ">= 0.14.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20.0"
    }
    http = {
      version = "~> 3.4.0"
    }
    random = {
      version = "~> 3.5.1"
    }
  }

  backend "s3" {
    bucket         = "tfstate-bucket-checkpoint-env"
    key            = "state/terraform.tfstate"
    region         = "il-central-1"
    encrypt        = true
    use_lockfile   = true
  }
}


provider "aws" {
  region                 = module.global.org_vars.region
  skip_region_validation = true
  profile                = "ps-LandingZoneAdmins-975050045686"
}

