#!/usr/bin/env bash
#
# Terraform state 管理用 S3 バケットを完全削除する(全バージョン含む)
#
# 使い方:
#   ./delete-state-bucket.sh [region]
#
set -euo pipefail

REGION="${1:-ap-northeast-1}"
PROJECT="${PROJECT:-kiro-ws}"
ENV="${ENV:-dev}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="${PROJECT}-${ENV}-tfstate-${ACCOUNT_ID}"

if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
  echo "bucket s3://${BUCKET} は存在しません"
  exit 0
fi

echo "!!! s3://${BUCKET} を全バージョン含めて完全削除します"
echo "!!! 全 Step の terraform state が失われます(復旧不可)"
read -r -p "本当に削除しますか? (yes と入力): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "中止しました"
  exit 1
fi

# --- 全オブジェクトバージョン + 削除マーカーを削除 ---
while true; do
  BATCH=$(aws s3api list-object-versions --bucket "$BUCKET" --max-keys 500 \
    --query '[Versions[].{Key:Key,VersionId:VersionId},DeleteMarkers[].{Key:Key,VersionId:VersionId}][][]' \
    --output json)

  COUNT=$(printf '%s' "$BATCH" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d or []))')
  [ "$COUNT" = "0" ] && break

  printf '%s' "$BATCH" | python3 -c '
import json, sys
objs = json.load(sys.stdin) or []
print(json.dumps({"Objects": objs[:1000], "Quiet": True}))' > /tmp/delete-batch.json

  aws s3api delete-objects --bucket "$BUCKET" --delete file:///tmp/delete-batch.json > /dev/null
  echo "    deleted ${COUNT} object versions..."
done

aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION"
echo "==> s3://${BUCKET} を削除しました"
echo "    リポジトリ直下の backend.hcl も不要であれば削除してください"
