#!/usr/bin/env bash
#
# postToolUse フック: エージェントが実行したシェルコマンドを監査ログに残す
#
# ハーネスエンジニアリングの Auditability(監査可能性)の実装例。
# ログ: .kiro/audit.log(タイムスタンプ / セッション ID / コマンド)
#
set -u

EVENT=$(cat)

printf '%s' "$EVENT" | python3 -c '
import json, sys, datetime, os
try:
    e = json.load(sys.stdin)
except Exception:
    sys.exit(0)
cmd = (e.get("tool_input") or {}).get("command", "")
if not cmd:
    sys.exit(0)
line = "{}\t{}\t{}\n".format(
    datetime.datetime.now().isoformat(timespec="seconds"),
    e.get("session_id", "-"),
    cmd.replace("\n", " "),
)
path = os.path.join(e.get("cwd", "."), ".kiro", "audit.log")
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "a") as f:
    f.write(line)
'

exit 0
