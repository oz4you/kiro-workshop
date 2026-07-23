#!/usr/bin/env bash
#
# preToolUse フック: plan を経ない terraform apply をブロックする
#
# Kiro CLI はフック実行時、STDIN にツールイベント(JSON)を渡す。
# exit 0 = 許可 / exit 2 = ブロック(STDERR が LLM に返る)
#
set -u

EVENT=$(cat)

# シェル実行ツールのコマンド文字列を取り出す
CMD=$(printf '%s' "$EVENT" | python3 -c '
import json, sys
try:
    e = json.load(sys.stdin)
    ti = e.get("tool_input", {})
    print(ti.get("command", "") or "")
except Exception:
    print("")
')

# terraform apply を含み、かつ plan ファイル経由でない場合はブロック
if printf '%s' "$CMD" | grep -qE '\bterraform\s+apply\b'; then
  if ! printf '%s' "$CMD" | grep -qE '\bterraform\s+apply\s+.*tfplan'; then
    echo "BLOCKED: terraform apply は plan ファイル経由でのみ実行できます。" >&2
    echo "先に 'terraform plan -out=tfplan' を実行して内容をユーザーに説明し、" >&2
    echo "承認を得てから 'terraform apply tfplan' を実行してください。" >&2
    exit 2
  fi
fi

# terraform destroy は常にブロック(ユーザー自身の明示実行に委ねる)
if printf '%s' "$CMD" | grep -qE '\bterraform\s+(destroy|apply\s+-destroy)\b'; then
  echo "BLOCKED: destroy はエージェントからは実行できません。" >&2
  echo "削除対象を plan -destroy で提示し、ユーザー自身に実行してもらってください。" >&2
  exit 2
fi

exit 0
