# ADR-004: Terraform ファイルを用途別に分割する

## ステータス

Accepted

## コンテキスト

VPC ネットワーク基盤の Terraform コードは合計約28リソースで、steering の structure.md が定める「main.tf が15リソースを超えたら分割」の上限を超過する。どのような粒度でファイルを分割するかの判断が必要になった。

## 決定

以下の3ファイルに用途別で分割する:

| ファイル | 内容 |
|---------|------|
| `main.tf` | VPC, IGW, サブネット, ルートテーブル, ルート, アソシエーション |
| `endpoints.tf` | VPC エンドポイント4つ, セキュリティグループ, ingress ルール |
| `flow_log.tf` | フローログ, ロググループ, IAM ロール, IAM ポリシー |

加えて `versions.tf`, `variables.tf`, `outputs.tf` を配置。

## 代替案

**全リソースを main.tf に集約する**

却下理由:
- 28リソースを1ファイルに詰め込むと可読性が著しく低下
- steering の structure.md に定める15リソース上限に違反
- 変更時の影響範囲が不明確になる

## 検証

| ツール | 確認内容 | 結果 |
|--------|----------|------|
| steering `structure.md` | 「main.tf が15リソースを超えたら分割」規約 | ✅ 28リソースで超過確認。分割は規約準拠 |
| steering `terraform-best-practices.md` | ファイル構成規約 | ✅ main.tf + 分割ファイル + variables.tf + outputs.tf + versions.tf の構成は推奨パターンに合致 |

## 帰結

- 用途別にファイルが分かれることで、変更影響範囲が明確になる
- 新たなリソース種別（例: ALB）は別の Step で別ファイルに追加するため、この Step 内での追加分割は不要
- **再検討トリガー**: 1ファイル内のリソースが再び15を超えた場合
