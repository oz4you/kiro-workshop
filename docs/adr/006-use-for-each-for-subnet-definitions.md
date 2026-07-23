# ADR-006: サブネット定義に for_each を使用する

## ステータス

Accepted

## コンテキスト

サブネットが6つ（3種類 × 2 AZ）あり、Terraform での定義方法として `for_each` による動的生成か、個別にハードコードするかの判断が必要になった。ワークショップの学習性と DRY 原則のバランスが論点。

## 決定

`for_each` を使い、AZ ごとの CIDR マップから動的にサブネットを生成する。

```hcl
resource "aws_subnet" "private_ecs_task" {
  for_each          = var.private_ecs_task_subnets
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.key
}
```

## 代替案

**個別に1つずつリソースを定義する**

```hcl
resource "aws_subnet" "private_ecs_task_1a" { ... }
resource "aws_subnet" "private_ecs_task_1c" { ... }
```

却下理由:
- steering の terraform-best-practices.md が「for_each for collections」を推奨
- 6リソース分の繰り返しが冗長で DRY 原則に反する
- `for_each` は Terraform の重要パターンで、ワークショップで学ぶ価値が高い
- AZ が2つ固定で map 構造が単純なため、学習コストも低い

## 検証

| ツール | 確認内容 | 結果 |
|--------|----------|------|
| steering `terraform-best-practices.md` | `for_each` の推奨規約 | ✅ 「for_each for distinct values」が明記されている |
| Terraform MCP `get_provider_details` (ID:12942884) | `aws_subnet` が `for_each` 対応であること | ✅ 標準的な resource ブロックで for_each 使用可能 |

## 帰結

- `for_each` の key 変更（AZ 追加/削除）時は `terraform state mv` が必要になる可能性がある
- 受講者に `for_each` + map の概念を説明するセクションが必要
- **再検討トリガー**: AZ を動的に取得するデータソースに切り替える場合
