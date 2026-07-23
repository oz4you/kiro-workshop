#!/usr/bin/env bash
#
# Terraform state 管理用 S3 バケットを作成する bootstrap スクリプト(冪等)
#
# なぜ Terraform ではなくシェルなのか:
#   state バケットは「Terraform が動くための前提」であり、
#   Terraform 自身で管理すると "このバケットの state は誰が管理するのか"
#   という鶏と卵の問題が残るため、素朴なスクリプトで作成・削除する。
#
# 使い方:
#   ./create-state-bucket.sh [region]
#
set -euo pipefail

REGION="${1:-ap-northeast-1}"
PROJECT="${PROJECT:-kiro-ws}"
ENV="${ENV:-dev}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${PROJECT}-${ENV}-tfstate-${ACCOUNT_ID}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> state bucket: s3://${BUCKET} (${REGION})"

# --- バケット作成(存在すればスキップ) ---
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "    already exists, skipping create"
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration "LocationConstraint=${REGION}"
  fi
  echo "    created"
fi

# --- バージョニング(state の誤破壊からの復旧用) ---
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# --- 暗号化(SSE-KMS + Bucket Key) ---
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "aws:kms"},
      "BucketKeyEnabled": true
    }]
  }'

# --- パブリックアクセスブロック ---
aws s3api put-public-access-block --bucket "$BUCKET" \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# --- 各 Step の terraform init で使う共通 backend 設定を生成 ---
cat > "${REPO_ROOT}/backend.hcl" <<EOF
# bootstrap/create-state-bucket.sh が生成したファイル(コミットしない)
# 使い方: terraform init -backend-config=../../backend.hcl
bucket = "${BUCKET}"
region = "${REGION}"
EOF

echo "==> done"
echo "    generated: ${REPO_ROOT}/backend.hcl"
echo "    次の手順: 各 Step の terraform ディレクトリで"
echo "      terraform init -backend-config=../../backend.hcl"
