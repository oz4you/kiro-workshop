# Project Structure

## ディレクトリ規約

- 各 Step は `stepN-<テーマ>/` ディレクトリで独立して完結する(Step 間のリモート state 参照はしない)
- Terraform コードは各 Step の `terraform/` サブディレクトリに置く

## Terraform ファイル分割規約

| ファイル | 内容 |
|----------|------|
| `versions.tf` | terraform ブロック、required_providers |
| `variables.tf` | 入力変数(全変数に description 必須) |
| `main.tf` | 主要リソース(大きくなる場合は `network.tf` 等に分割) |
| `outputs.tf` | 出力値 |

## 命名規約

- リソース名: `<project>-<env>-<用途>` 形式(例: `kiro-ws-dev-vpc`)
- Terraform リソースのローカル名: スネークケース、リソース種別を繰り返さない(`aws_vpc.main` であって `aws_vpc.vpc` としない)
- 変数 `project` と `env` を全 Step で共通利用し、default は `kiro-ws` / `dev`
- 全リソースに `tags` を付与(default_tags で `Project`、`ManagedBy = terraform` を設定)
