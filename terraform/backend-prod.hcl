bucket         = "my2-terraform2-state2-prod"    # From bootstrap
key            = "terraform/aws.tfstate"# Path inside bucket
region         = "us-east-1"
dynamodb_table = "terraform-lock-prod"          # From bootstrap
