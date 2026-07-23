# Tasks: vpc-network

## 概要

design.md に基づき、VPC ネットワーク基盤を段階的に実装する。
各タスクは独立して PR 可能な粒度で、`terraform validate` が通る状態を完了条件とする。

---

## タスク一覧

- [ ] 1. プロジェクト基盤の作成（versions.tf, variables.tf） (#3)
  - **対応要件**: AC-1.1, AC-1.3, C-1, C-4
  - **関連 ADR**: なし
  - **完了条件**:
    - `step1-vpc-network/terraform/versions.tf` に terraform ブロック（required_version >= 1.9）、required_providers（hashicorp/aws ~> 6.21）、provider ブロック（region = var.aws_region）、default_tags（Project, ManagedBy）を定義
    - `step1-vpc-network/terraform/variables.tf` に全入力変数を定義（project, env, aws_region, VPC CIDR, サブネット CIDR マップ）
    - 全変数に description を付与
    - `terraform init` && `terraform validate` が成功する

- [ ] 2. VPC・サブネット・ルーティングの実装（main.tf） (#4)
  - **対応要件**: AC-1.1, AC-1.2, AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5
  - **関連 ADR**: ADR-001, ADR-005, ADR-006
  - **完了条件**:
    - `aws_vpc` を CIDR 10.0.0.0/20、DNS ホスト名・DNS サポート有効で作成
    - `aws_internet_gateway` を VPC に紐付け
    - `aws_subnet` を `for_each` で3種類 × 2 AZ 作成（Name タグ: `kiro-ws-dev-<用途>-<az suffix>`）
    - ルートテーブル3つ（public, private-ecs-task, private-data）を作成
    - public ルートテーブルに 0.0.0.0/0 → IGW のルートを追加
    - 各サブネットにルートテーブルを `for_each` で関連付け
    - `terraform validate` が成功する

- [ ] 3. VPC エンドポイントとセキュリティグループの実装（endpoints.tf） (#1)
  - **対応要件**: AC-3.1, AC-3.2, AC-3.3, AC-3.4, AC-3.5, AC-3.6, AC-5.1, AC-5.2, AC-5.3
  - **関連 ADR**: ADR-002, ADR-007
  - **完了条件**:
    - `aws_security_group`（インラインルールなし）を VPC エンドポイント用に作成
    - `aws_vpc_security_group_ingress_rule` で VPC CIDR → 443/tcp を許可
    - Interface エンドポイント3つ（ecr.api, ecr.dkr, logs）を private-ecs-task サブネットに配置、プライベート DNS 有効
    - Gateway エンドポイント1つ（S3）を private-ecs-task と private-data 両方のルートテーブルに関連付け
    - 0.0.0.0/0 からのインバウンドが存在しないことを確認
    - `terraform validate` が成功する

- [ ] 4. VPC フローログの実装（flow_log.tf） (#2)
  - **対応要件**: AC-4.1, AC-4.2, AC-4.3
  - **関連 ADR**: ADR-003
  - **完了条件**:
    - `aws_cloudwatch_log_group` を保持期間7日で作成
    - `aws_iam_role` を vpc-flow-logs.amazonaws.com のみ信頼する trust policy で作成（confused deputy 対策の `aws:SourceAccount` 条件を含む）
    - `aws_iam_role_policy` でログ書き込み5アクションを当該ロググループ ARN に限定して付与
    - `aws_flow_log` で VPC 全体の ALL トラフィックを CloudWatch Logs に出力
    - `terraform validate` が成功する

- [ ] 5. Outputs の定義（outputs.tf） (#6)
  - **対応要件**: design.md Outputs セクション
  - **関連 ADR**: なし
  - **完了条件**:
    - `vpc_id`, `vpc_cidr_block`, `public_subnet_ids`, `private_ecs_task_subnet_ids`, `private_data_subnet_ids`, `vpc_endpoint_sg_id` を出力
    - 全 output に description を付与
    - `terraform validate` が成功する

- [ ] 6. 統合検証と terraform plan (#5)
  - **対応要件**: 全 AC, NFR-1, NFR-2, NFR-4
  - **関連 ADR**: 全 ADR
  - **完了条件**:
    - `terraform fmt -check` が差分なし
    - `terraform validate` が成功
    - `terraform plan` を実行し、想定リソース数（約28）が表示される
    - コスト見積もりを提示（月額 $63〜68）
    - セキュリティ確認: SG に 0.0.0.0/0 ingress なし、プライベートサブネットに IGW ルートなし
    - README.md を作成（概要、使い方、コスト、クリーンアップ手順）
