# ADR-003: VPC フローログ専用の最小権限 IAM ロールを使用する

## ステータス

Accepted

## コンテキスト

VPC フローログを CloudWatch Logs に出力するために IAM ロールが必要。フローログ専用で最小権限のロールを作るか、将来の他用途（例: Lambda のログ出力）にも使い回せる汎用的なロールを作るかの判断が必要になった。steering の terraform-standards.md は「IAM ポリシーは最小権限」を要求している。

## 決定

フローログ専用の IAM ロールを作成する。構成:

- **Trust policy**: `vpc-flow-logs.amazonaws.com` のみ信頼
- **Permissions**: `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`, `logs:DescribeLogGroups`, `logs:DescribeLogStreams`
- **Resource**: 当該ロググループ ARN に限定
- **推奨**: trust policy に `aws:SourceAccount` 条件を追加して confused deputy 対策を実施する

## 代替案

**汎用ログ書き込みロールを作り、複数サービスで使い回す**

却下理由:
- Resource ARN が広くなり、意図しないロググループへの書き込みが可能になるリスク
- steering の terraform-standards.md が最小権限を要求
- 複数サービスが同一ロールを共有すると、変更時の影響範囲が不明確になる

## 検証

| ツール | 確認内容 | 結果 |
|--------|----------|------|
| AWS Documentation MCP `read_documentation` | [flow-logs-iam-role.html](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-iam-role.html) の公式要件 | ✅ 必要アクション5つと trust policy（vpc-flow-logs.amazonaws.com）を確認 |
| AWS Documentation MCP | confused deputy 対策の推奨 | ✅ AWS が `aws:SourceAccount` と `aws:SourceArn` 条件の追加を明示的に推奨 |
| Terraform MCP `get_provider_details` (ID:12942040) | `aws_flow_log` の `iam_role_arn` 引数 | ✅ 存在確認済み |
| steering `terraform-standards.md` | IAM 最小権限規約 | ✅ Resource を特定 ARN に絞る方針は規約準拠 |

### confused deputy 対策について

AWS 公式ドキュメントでは trust policy に以下の条件追加を推奨:

```json
"Condition": {
    "StringEquals": {
        "aws:SourceAccount": "account_id"
    },
    "ArnLike": {
        "aws:SourceArn": "arn:aws:ec2:region:account_id:vpc-flow-log/*"
    }
}
```

実装時にフローログ ID が未確定の場合はワイルドカードを使用し、作成後に更新する方針とする。

## 帰結

- フローログ以外の用途（Lambda、ECS 等）には別途 IAM ロールを作成する必要がある（これは意図した制約）
- **再検討トリガー**: 同一アカウント内で複数の VPC フローログが増え、ロール管理のオーバーヘッドが問題になった場合
