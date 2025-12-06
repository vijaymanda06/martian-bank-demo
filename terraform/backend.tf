# S3 Backend Configuration with DynamoDB Locking
#
# Before using this backend, create the S3 bucket and DynamoDB table:
#
# aws s3api create-bucket --bucket martianbank-terraform-state --region us-west-2 \
#   --create-bucket-configuration LocationConstraint=us-west-2
#
# aws s3api put-bucket-versioning --bucket martianbank-terraform-state \
#   --versioning-configuration Status=Enabled
#
# aws dynamodb create-table --table-name martianbank-terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST

terraform {
  backend "s3" {
    bucket         = "martianbank-terraform-state-usw1"
    key            = "martianbank/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "martianbank-terraform-locks"
  }
}
