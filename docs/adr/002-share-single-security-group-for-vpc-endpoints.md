# ADR-002: VPC エンドポイント用セキュリティグループを共有する

## ステータス

Accepted

## コンテキスト

Interface 型 VPC エンドポイントが3つ（ecr.api, ecr.dkr, logs）あり、それぞれにセキュリティグループが必要。すべて同じルール（VPC CIDR からの HTTPS 443 インバウンドのみ）であるため、SG を共有するか個別に作るかの判断が必要になった。

## 決定

3つの Interface エンドポイントで1つのセキュリティグループを共有する。

## 代替案

**エンドポイントごとに個別のセキュリティグループを作る**

却下理由:
- 現時点では3つすべてが同一ルール（VPC CIDR → 443/tcp）であり、分離する実益がない
- リソース数が増えコードが冗長になる
- YAGNI 原則に従い、将来必要になった時点で分離すれば十分

## 検証

| ツール | 確認内容 | 結果 |
|--------|----------|------|
| AWS Documentation MCP `search_documentation` | Interface VPC エンドポイントの SG 設計パターン | ✅ SageMaker ドキュメント (model-customize-mtrl-vpc.html) で「A security group shared by all interface endpoints that allows inbound TCP 443 from the VPC CIDR」パターンを確認 |
| Terraform MCP `get_provider_details` (ID:12942930) | `aws_vpc_endpoint` の `security_group_ids` 引数がリスト型であること | ✅ 確認済み。複数エンドポイントで同一 SG ID を指定可能 |
| steering `terraform-standards.md` | 0.0.0.0/0 ingress 禁止規約 | ✅ VPC CIDR のみ許可で規約準拠 |

## 帰結

- エンドポイント追加時に異なるルールが必要になった場合、SG を分離する新しい ADR を起票して対応する
- **再検討トリガー**: エンドポイントごとに異なるソース IP 制限が必要になった場合
