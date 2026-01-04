bucket         = "my2-terraform2-state2-stage"    # From bootstrap
key            = "terraform/aws.tfstate"       # Path inside bucket
region         = "us-east-1"
dynamodb_table = "terraform-lock-stage"          # From bootstrap
