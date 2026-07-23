# 疎通確認用の最小Terraform構成（リソースは作成しません）
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # AWS_PROFILE 環境変数で指定されたSSOプロファイルを使用
}

# 現在の認証情報を確認するだけのデータソース
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
