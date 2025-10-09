# Backend remoto listo para cuando quieras mover el estado.
# Quitar los comentarios y completar tus valores en AWS.
#
# terraform {
#   backend "s3" {
#     bucket         = "TU-BUCKET-TERRAFORM"
#     key            = "state/proyecto-devops/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }