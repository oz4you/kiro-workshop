# Technology Stack

## IaC

- Terraform >= 1.9(HCL)
- AWS プロバイダ: hashicorp/aws ~> 6.21(AgentCore リソース対応版)
- CDK や CloudFormation は使用しない

## AWS

- リージョン: ap-northeast-1(東京)を既定とする
- 認証: AWS_PROFILE 環境変数(ハードコード禁止)

## その他

- CI/CD: GitHub Actions(OIDC 認証。長期アクセスキーは使用禁止)
- コンテナ: ECS Fargate(EC2 起動タイプは使用しない)
- AI エージェント: Strands Agents(Python)+ Amazon Bedrock AgentCore Runtime
