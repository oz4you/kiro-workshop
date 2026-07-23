# Bootstrap: Terraform state 管理基盤

全 Step の Terraform state は、ここで作成する **1つの S3 バケット**で集中管理します(Step ごとに `key` を分離)。

## なぜシェルスクリプトなのか

state バケットは「Terraform が動くための前提」です。Terraform 自身で作ると「そのバケットの state は誰が管理するのか」という鶏と卵の問題が発生します。本ワークショップでは、この境界を **冪等なシェルスクリプト**で明示的に切ります。

## 使い方

```bash
cd bootstrap
./create-state-bucket.sh          # ap-northeast-1 に作成
```

実行すると以下が行われます:

1. `kiro-ws-dev-tfstate-<アカウントID>` バケットを作成(存在すればスキップ)
2. バージョニング / SSE-KMS 暗号化 / パブリックアクセスブロックを設定
3. リポジトリ直下に **`backend.hcl`** を生成(バケット名とリージョン)

各 Step ではこの `backend.hcl` を使って初期化します:

```bash
cd step1-basic-vpc/terraform
terraform init -backend-config=../../backend.hcl
```

各 Step の `backend.tf` には `key = "stepN/terraform.tfstate"` と `use_lockfile = true`(S3 ネイティブロック、Terraform 1.10+)だけを書き、バケット名は `backend.hcl` から注入します。

## 削除(ワークショップ完全終了時)

```bash
./delete-state-bucket.sh    # 全バージョン削除 + バケット削除(要 yes 入力)
```

**注意:** 全 Step の state が失われます。各 Step のリソースを `terraform destroy` してから実行してください。

## 学習ポイント

- `backend.hcl` は環境固有ファイルなのでコミットしない(`.gitignore` 済み)。CI では GitHub Actions の Variables から同等の設定を生成します(Step 2 参照)
- 「どこまでを IaC にし、どこからを bootstrap にするか」という境界設計は、Kiro に「state バケットを Terraform 管理にする場合の選択肢と比較して」と聞いてみると理解が深まります
