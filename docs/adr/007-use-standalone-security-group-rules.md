# ADR-007: セキュリティグループルールをスタンドアロンリソースで定義する

## ステータス

Accepted

## コンテキスト

VPC エンドポイント用セキュリティグループの ingress ルールを定義する方法として、`aws_security_group` のインライン `ingress` ブロックを使う方法と、`aws_vpc_security_group_ingress_rule` リソースを別途定義する方法がある。プロバイダの推奨に従うべきか判断が必要になった。

## 決定

`aws_vpc_security_group_ingress_rule`（スタンドアロンリソース）を使用する。`aws_security_group` リソースでは `ingress`/`egress` ブロックを使わない。

## 代替案

**`aws_security_group` のインラインルール（`ingress`/`egress` ブロック）を使用する**

却下理由:
- hashicorp/aws プロバイダ v6.56.0 の公式ドキュメントでスタンドアロンルールが「current best practice」と明記
- インラインルールは複数 CIDR ブロック、タグ、description の管理に問題がある
- インラインルールとスタンドアロンルールを混在させると「rule conflicts, perpetual differences」が発生する
- steering の terraform-standards.md が「非推奨の引数・リソースを使わない」と規定

## 検証

| ツール | 確認内容 | 結果 |
|--------|----------|------|
| Terraform MCP `get_provider_details` (ID:12942962) | `aws_vpc_security_group_ingress_rule` のドキュメント | ✅ 「Using aws_vpc_security_group_ingress_rule resources is the current best practice」と明記 |
| Terraform MCP `get_provider_details` (ID:12942733) | `aws_security_group` のドキュメント | ✅ 「Avoid using the ingress and egress arguments」と非推奨明記 |
| steering `terraform-standards.md` | 非推奨リソース・引数の使用禁止 | ✅ 規約準拠 |

## 帰結

- ルールの追加・削除が個別リソースの追加・削除で完結し、他ルールに影響しない
- `aws_security_group` リソースは SG の箱だけを定義し、ルールは別リソースで管理する
- **再検討トリガー**: プロバイダが新しいルール管理方式を導入した場合
