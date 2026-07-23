# Terraform Coding Standards

Kiro が Terraform コードを生成・修正する際は以下を厳守すること。

## セキュリティ

- セキュリティグループで `0.0.0.0/0` の ingress を許可するのは ALB の 80/443 のみ。それ以外は理由をコメントで明記し、ユーザーに確認を取る
- S3 バケットは必ず Public Access Block を有効化
- IAM ポリシーは最小権限。`Action: "*"` や `Resource: "*"` を安易に使わない(使う場合は理由をコメント)
- IAM ロール/ユーザーを作成・変更した場合、可能であれば `awslabs.iam-mcp-server` の `simulate_principal_policy` で**実際に意図した操作以外ができないこと**を検証する。目視レビューだけで「最小権限」を主張しない
- 秘匿情報(API キー、パスワード)を .tf ファイルや state にハードコードしない。SSM Parameter Store / Secrets Manager を参照する
- IMDSv2 を必須化(EC2 を使う場合)

## 品質

- `terraform fmt` 済みの整形で出力する
- マジックナンバーは variable 化または locals 化
- 変更を提案する際は、まず `terraform plan` の想定結果を説明してから apply を促す
- 非推奨(deprecated)の引数・リソースを使わない。不明な場合は Terraform MCP サーバでプロバイダドキュメントを確認する

## コスト

- **apply の前にコスト見積もりを提示する。** 課金対象リソース(NAT Gateway、ALB、Fargate、Interface 型 VPC エンドポイント等)を含む plan を実行する前に、月額概算をユーザーに示す
- 単価は推測せず AWS Pricing MCP サーバで確認する
- 成果物として残す場合は `/cost-estimate` スキルのフォーマットに従う

## レビュー観点

コードレビューを求められたら以下の順で確認する:

1. セキュリティ(上記違反の有無)。IAM ロールを含む場合は `simulate_principal_policy` での実測検証を優先する
2. 冪等性(再 apply で差分が出ない構成か)
3. 命名・タグ付け規約への準拠
4. コスト(不要な高額リソースがないか)
