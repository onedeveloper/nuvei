terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = "~> 1.7.2"

  backend "consul" {
    address = "localhost:8500"
    path    = "nuvai/dev/state"
    scheme  = "http"
  }

}

provider "aws" {
  region = "us-east-1"
}