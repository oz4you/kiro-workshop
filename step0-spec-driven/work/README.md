# Step 0: VPC ネットワーク基盤

ECS Fargate ワークロード向けの VPC ネットワーク基盤を構築する Terraform コード。
NAT Gateway を使わず VPC エンドポイント経由で AWS サービスにアクセスするコスト効率の良い構成。

## アーキテクチャ

```
VPC 10.0.0.0/20 (ap-northeast-1)
├── Public Subnets (/26 × 2 AZ)
│   └── Internet Gateway 経由でインターネットアクセス
├── Private ECS Task Subnets (/23 × 2 AZ)
│   └── VPC Endpoints 経由で AWS サービスにアクセス
├── Private Data Subnets (/24 × 2 AZ)
│   └── S3 Gateway Endpoint のみ
├── VPC Endpoints
│   ├── ecr.api (Interface)
│   ├── ecr.dkr (Interface)
│   ├── logs (Interface)
│   └── s3 (Gateway)
└── VPC Flow Logs → CloudWatch Logs (7日保持)
```

## 前提条件

- Terraform >= 1.9
- AWS CLI（認証設定済み）
- AWS プロバイダ ~> 6.21

## 使い方

### 初期化

```bash
cd step0-spec-driven/work
terraform init
```

### Plan（変更内容の確認）

```bash
terraform plan
```

28 リソースが作成される想定です。

### Apply（リソース作成）

```bash
terraform apply
```

### 変数のカスタマイズ

`terraform.tfvars` を作成して変数を上書きできます：

```hcl
project = "my-project"
env     = "dev"
```

デフォルト値：

| 変数 | デフォルト | 説明 |
|------|-----------|------|
| `project` | `kiro-ws` | プロジェクト名（リソース命名に使用） |
| `env` | `dev` | 環境名 |
| `aws_region` | `ap-northeast-1` | デプロイリージョン |
| `vpc_cidr` | `10.0.0.0/20` | VPC の CIDR ブロック |

## コスト見積もり

| リソース | 月額概算 |
|---------|---------|
| Interface VPC Endpoint (3個 × 2 AZ) | $61.32 |
| S3 Gateway Endpoint | 無料 |
| VPC フローログ (CloudWatch Logs) | $1〜5 |
| VPC / Subnets / IGW / Route Tables | 無料 |
| **合計** | **約 $63〜68** |

### 単価根拠（ap-northeast-1, AWS Pricing API 確認済み）

- Interface VPC Endpoint: $0.014/h/ENI + $0.01/GB（データ処理）
- Vended Logs (CloudWatch): $0.76/GB（10TB 未満）

> ⚠️ **注意**: Interface VPC Endpoint は稼働時間で課金されます。学習が終わったら必ず `terraform destroy` で削除してください。

## セキュリティ

- セキュリティグループは VPC CIDR → 443/tcp のみ許可（0.0.0.0/0 ingress なし）
- プライベートサブネットにはインターネットへの直接ルートなし
- IAM ロールは最小権限（フローログ専用、ロググループ ARN 限定）
- Confused deputy 対策の条件付き trust policy

## クリーンアップ

学習が終わったら、以下のコマンドでリソースを削除してください：

```bash
terraform destroy
```

`destroy` 実行後、以下が削除されます：

- VPC および全サブネット
- Internet Gateway
- VPC エンドポイント（Interface × 3, Gateway × 1）
- セキュリティグループ
- ルートテーブルとルート
- CloudWatch Logs グループ（フローログ）
- IAM ロール・ポリシー
- VPC フローログ

## ファイル構成

| ファイル | 内容 |
|---------|------|
| `versions.tf` | Terraform/プロバイダバージョン、default_tags |
| `variables.tf` | 入力変数（VPC CIDR、サブネット CIDR 等） |
| `main.tf` | VPC、IGW、サブネット、ルートテーブル |
| `endpoints.tf` | VPC エンドポイント、セキュリティグループ |
| `flow_log.tf` | VPC フローログ、IAM ロール |
| `outputs.tf` | 出力値（vpc_id, subnet_ids 等） |

## 関連ドキュメント

- [Requirements](.kiro/specs/vpc-network/requirements.md)
- [Design](.kiro/specs/vpc-network/design.md)
- [ADR 一覧](docs/adr/)
