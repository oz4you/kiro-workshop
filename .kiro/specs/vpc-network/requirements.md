# Requirements: vpc-network

## 概要

ECS Fargate ワークロードを動作させるための VPC ネットワーク基盤を構築する。
NAT Gateway を使わず VPC エンドポイント経由で AWS サービスにアクセスするコスト効率の良い構成。

## ユーザーストーリー

### US-1: VPC 作成

**As a** ワークショップ受講者
**I want to** ECS Fargate 用の VPC を作成する
**So that** コンテナワークロードを安全に動作させるネットワーク基盤が手に入る

#### 受入条件

- AC-1.1: WHEN Terraform apply が完了した THEN システムは CIDR 10.0.0.0/20 の VPC を ap-northeast-1 に作成する SHALL
- AC-1.2: WHEN VPC が作成された THEN システムは DNS ホスト名と DNS サポートを有効化する SHALL
- AC-1.3: WHEN VPC が作成された THEN システムは default_tags により Project, ManagedBy タグを付与する SHALL

### US-2: サブネット配置

**As a** ワークショップ受講者
**I want to** 用途別に分離されたサブネットを持つ
**So that** ワークロード、データ、外部公開を適切に分離できる

#### 受入条件

- AC-2.1: WHEN VPC が存在する THEN システムは 2 AZ（ap-northeast-1a, 1c）にサブネットを配置する SHALL
- AC-2.2: WHEN サブネットが作成される THEN システムは以下の構成で作成する SHALL
  - パブリック（public）: /26 × 2 AZ（10.0.0.0/26, 10.0.0.64/26）
  - プライベート ECS タスク用（private-ecs-task）: /23 × 2 AZ（10.0.2.0/23, 10.0.4.0/23）
  - プライベート データ用（private-data）: /24 × 2 AZ（10.0.12.0/24, 10.0.13.0/24）
- AC-2.3: WHEN パブリックサブネットが作成される THEN システムはインターネットゲートウェイへのルートを持つルートテーブルを関連付ける SHALL
- AC-2.4: WHEN プライベートサブネットが作成される THEN システムはインターネットへの直接ルートを持たないルートテーブルを関連付ける SHALL
- AC-2.5: WHEN サブネットが作成される THEN システムは `kiro-ws-dev-<用途>-<az>` 形式の Name タグを付与する SHALL

### US-3: VPC エンドポイント

**As a** ワークショップ受講者
**I want to** NAT Gateway なしでプライベートサブネットから AWS サービスにアクセスする
**So that** コストを抑えつつセキュアな通信を実現できる

#### 受入条件

- AC-3.1: WHEN プライベートサブネットから ECR へのアクセスが必要な THEN システムは ecr.api 用 Interface エンドポイントを作成する SHALL
- AC-3.2: WHEN プライベートサブネットから Docker イメージの Pull が必要な THEN システムは ecr.dkr 用 Interface エンドポイントを作成する SHALL
- AC-3.3: WHEN プライベートサブネットから CloudWatch Logs への送信が必要な THEN システムは logs 用 Interface エンドポイントを作成する SHALL
- AC-3.4: WHEN プライベートサブネットから S3 へのアクセスが必要な THEN システムは S3 用 Gateway エンドポイントを作成する SHALL
- AC-3.5: WHEN Interface エンドポイントが作成される THEN システムはプライベート DNS を有効化する SHALL
- AC-3.6: WHEN Interface エンドポイントが作成される THEN システムは private-ecs-task サブネットに配置する SHALL

### US-4: VPC フローログ

**As a** ワークショップ受講者
**I want to** VPC のネットワークトラフィックを記録する
**So that** 学習中にネットワークの動きを確認・調査できる

#### 受入条件

- AC-4.1: WHEN VPC が作成された THEN システムは VPC フローログを有効化し CloudWatch Logs に出力する SHALL
- AC-4.2: WHEN フローログが作成される THEN システムは専用の IAM ロールとロググループを作成する SHALL
- AC-4.3: WHEN フローログのロググループが作成される THEN システムは保持期間を 7 日間に設定する SHALL（コスト抑制）

### US-5: セキュリティグループ

**As a** ワークショップ受講者
**I want to** VPC エンドポイント用のセキュリティグループを持つ
**So that** エンドポイントへの通信を最小権限で制御できる

#### 受入条件

- AC-5.1: WHEN Interface エンドポイントが作成される THEN システムは専用のセキュリティグループを関連付ける SHALL
- AC-5.2: WHEN エンドポイント用セキュリティグループが作成される THEN システムは VPC CIDR からの HTTPS（443）インバウンドのみ許可する SHALL
- AC-5.3: WHEN セキュリティグループが作成される THEN システムは 0.0.0.0/0 からのインバウンドを許可しない SHALL

## 非機能要件

### セキュリティ

- NFR-1: terraform-standards.md に準拠（0.0.0.0/0 ingress は ALB 80/443 のみ）
- NFR-2: プライベートサブネットからインターネットへの直接アクセス経路なし
- NFR-3: IMDSv2 必須化（EC2 を使う場合。本 Step ではスコープ外）

### コスト

- NFR-4: 月額コスト概算
  - Interface VPC エンドポイント: 3 × 2 AZ × $0.014/h × 730h = **$61.32/月**
  - S3 Gateway エンドポイント: **無料**
  - VPC フローログ（CloudWatch Logs）: **~$1〜5/月**（データ量依存）
  - データ処理料: **~$1〜2/月**（学習用で微量）
  - **合計: 約 $63〜68/月**

### 可用性

- NFR-5: 2 AZ 構成（学習用途のため、本番レベルの SLA は不要）

## 制約

- C-1: リージョンは ap-northeast-1（東京）固定
- C-2: 既存 VPC・ネットワークリソースなし（新規構築）
- C-3: NAT Gateway は使用しない
- C-4: AWS プロバイダ ~> 6.21 を使用

## スコープ外

- NAT Gateway
- VPN / Direct Connect
- Transit Gateway / VPC ピアリング
- ALB / ECS タスク定義（後続 Step で作成）
- Bedrock 向け VPC エンドポイント（必要時に追加）
- マルチアカウント構成
- EC2 インスタンス
