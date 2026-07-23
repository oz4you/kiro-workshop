# ADR-001: VPC 構築に個別リソースを使用する

## ステータス

Accepted

## コンテキスト

VPC ネットワーク基盤を Terraform で構築する際、公開モジュール（terraform-aws-modules/vpc/aws）を使う方法と、個別リソース（aws_vpc, aws_subnet 等）を直接定義する方法がある。本ワークショップは「受講者が Terraform での AWS インフラ構築を段階的に習得する」ことが目的であり、どちらが学習効果が高いか判断が必要になった。

## 決定

個別リソース（aws_vpc, aws_subnet, aws_internet_gateway, aws_route_table 等）を直接定義する。

## 代替案

**terraform-aws-modules/vpc/aws モジュールを使用する**

却下理由:
- モジュールは VPC・サブネット・ルートテーブル・IGW をまとめて宣言的に書けるが、抽象化が進みすぎて初学者には中身がブラックボックスになる
- 各コンポーネントの関係性（VPC→サブネット→ルートテーブル→ルート）を理解する機会が失われる
- ワークショップの学習目的に照らすと、コード量が増えても個別リソースで書く方が教育効果が高い

## 検証

| ツール | 確認内容 | 結果 |
|--------|----------|------|
| Terraform MCP `search_providers` | `aws_vpc` (ID:12942924), `aws_subnet` (ID:12942884) がプロバイダ v6.56.0 に存在するか | ✅ 存在確認済み |
| Terraform MCP `get_provider_details` | `aws_vpc` の `enable_dns_hostnames`, `enable_dns_support`, `cidr_block` 引数 | ✅ 全て利用可能 |
| Terraform MCP `get_latest_provider_version` | hashicorp/aws 最新 6.56.0 と ~> 6.21 制約の互換性 | ✅ 互換 |

## 帰結

- コード量は約28リソースと多くなるが、受講者が「何が作られるか」を逐一把握できる
- 実務でモジュール利用に移行する際の基礎知識となる
- ファイル分割（ADR-004）により可読性を担保する
- **再検討トリガー**: ワークショップの対象者が中級以上に変更された場合
