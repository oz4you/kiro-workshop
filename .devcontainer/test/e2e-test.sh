#!/usr/bin/env bash
# DevContainer E2Eテスト: postCreate.shで導入したソフトウェア/MCPサーバーの動作確認
# 実行方法:
#   devcontainer exec --workspace-folder <path> -- bash .devcontainer/test/e2e-test.sh
set -uo pipefail
FAIL=0

# MCPサーバー設定(.kiro/settings/mcp.json や .mcp.json)はワークスペース/プロジェクト単位で
# カレントディレクトリ基準に解決されるため、サブディレクトリから実行すると
# kiro-cli / claude のどちらも設定を見つけられず「未設定」扱いになる。
# そのためリポジトリルートへ強制的に移動してから各チェックを実行する。
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "${PROJECT_ROOT}" ]; then
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
cd "${PROJECT_ROOT}"
echo "実行ディレクトリ: ${PROJECT_ROOT}"
echo

check() {
  local name="$1"; shift
  echo "== ${name} =="
  if "$@"; then
    echo "OK: ${name}"
  else
    echo "NG: ${name}"
    FAIL=1
  fi
  echo
}

# claude mcp list/get 用: 終了コードが0でも "Pending approval"(ワークスペース未信頼)
# が出力に含まれていたら未接続とみなして失敗扱いにする
check_claude_mcp() {
  local name="$1"; shift
  echo "== ${name} =="
  local out
  if out="$("$@" 2>&1)"; then
    echo "${out}"
    if echo "${out}" | grep -q "Pending approval"; then
      echo "NG: ${name} (Pending approval: \`claude\` を対話実行してワークスペースを信頼してください)"
      FAIL=1
    else
      echo "OK: ${name}"
    fi
  else
    echo "${out}"
    echo "NG: ${name}"
    FAIL=1
  fi
  echo
}

### 1. 基本ツールの動作確認 ###

check "kiro-cli --version" bash -lc "kiro-cli --version"

TF_DIR="$(mktemp -d)"
cat > "${TF_DIR}/main.tf" <<'EOF'
terraform {
  required_providers { local = { source = "hashicorp/local" } }
}
resource "local_file" "e2e" {
  content  = "e2e-test"
  filename = "${path.module}/e2e-test.txt"
}
EOF
check "terraform init"     bash -lc "cd '${TF_DIR}' && terraform init -input=false"
check "terraform validate" bash -lc "cd '${TF_DIR}' && terraform validate"
check "terraform apply"    bash -lc "cd '${TF_DIR}' && terraform apply -auto-approve -input=false && test -f '${TF_DIR}/e2e-test.txt'"
rm -rf "${TF_DIR}"

check "tflint --version" bash -lc "tflint --version"
check "aws sts get-caller-identity" bash -lc "aws sts get-caller-identity --profile \"\${AWS_PROFILE:-dev}\""
check "claude --version" bash -lc "claude --version"
check "gh --version" bash -lc "gh --version"

### 2. MCPサーバーの疎通確認 (.mcp.json / .kiro/settings/mcp.json に定義済み) ###
# 対象: aws-knowledge (HTTP), terraform (uvx経由のローカルサーバー)

# --- Kiro CLI 側 ---
check "kiro-cli mcp list" bash -lc "kiro-cli mcp list"
check "kiro-cli mcp status: aws-knowledge" bash -lc "kiro-cli mcp status --name aws-knowledge"
check "kiro-cli mcp status: terraform"     bash -lc "kiro-cli mcp status --name terraform"
check "kiro-cli mcp status: aws"           bash -lc "kiro-cli mcp status --name aws"
check "kiro-cli mcp status: aws-documentation" bash -lc "kiro-cli mcp status --name awslabs.aws-documentation-mcp-server"
check "kiro-cli mcp status: well-architected"  bash -lc "kiro-cli mcp status --name well-architected-security-mcp-server"
check "kiro-cli mcp status: github"        bash -lc "kiro-cli mcp status --name github"
check "kiro-cli mcp status: aws-pricing"   bash -lc "kiro-cli mcp status --name awslabs.aws-pricing-mcp-server"
check "kiro-cli mcp status: cloudtrail"    bash -lc "kiro-cli mcp status --name awslabs.cloudtrail-mcp-server"
check "kiro-cli mcp status: iam"           bash -lc "kiro-cli mcp status --name awslabs.iam-mcp-server"
check "kiro-cli mcp status: context7"      bash -lc "kiro-cli mcp status --name context7"

# uvx系サーバー(aws-documentation/well-architected/aws-pricing/cloudtrail/iam等)は
# 初回起動時にPython venv解決が発生し、MCPサーバー10個を同時起動する非対話モードでは
# デフォルトタイムアウトに間に合わず稀に失敗することがあるため、タイムアウトを緩和する。
kiro-cli settings mcp.noInteractiveTimeout 60000 >/dev/null 2>&1 || true

# 実際にchatセッションを起動し、MCPサーバーが1つでも起動失敗すると
# 終了コード3を返す(--require-mcp-startup)。これがMCP全体のE2E判定として一番確実。
# 起動タイミングのブレを吸収するため、失敗時は最大3回まで再試行する。
echo "== kiro-cli chat MCP起動確認 =="
mcp_startup_ok=0
for i in 1 2 3; do
  if kiro-cli chat --no-interactive --require-mcp-startup --trust-all-tools 'ok' </dev/null; then
    mcp_startup_ok=1
    break
  fi
  echo "（${i}回目失敗。3秒待って再試行します...）"
  sleep 3
done
if [ "$mcp_startup_ok" -eq 1 ]; then
  echo "OK: kiro-cli chat MCP起動確認"
else
  echo "NG: kiro-cli chat MCP起動確認（3回試行しても失敗）"
  FAIL=1
fi
echo

# --- Claude Code 側 ---
# 注意: プロジェクトスコープの.mcp.jsonはワークスペース信頼が必要。
# 自動テストで承認待ち(Pending approval)にならないようにするには
# .claude/settings.json に "enableAllProjectMcpServers": true を設定するか、
# 事前に `claude` を対話実行してワークスペースを信頼させておくこと。
check_claude_mcp "claude mcp list" bash -lc "claude mcp list"
check_claude_mcp "claude mcp get: aws-knowledge" bash -lc "claude mcp get aws-knowledge"
check_claude_mcp "claude mcp get: terraform"     bash -lc "claude mcp get terraform"
check_claude_mcp "claude mcp get: aws"             bash -lc "claude mcp get aws"
check_claude_mcp "claude mcp get: aws-documentation" bash -lc "claude mcp get awslabs.aws-documentation-mcp-server"
check_claude_mcp "claude mcp get: well-architected"  bash -lc "claude mcp get well-architected-security-mcp-server"
check_claude_mcp "claude mcp get: github"          bash -lc "claude mcp get github"
check_claude_mcp "claude mcp get: aws-pricing"     bash -lc "claude mcp get awslabs.aws-pricing-mcp-server"
check_claude_mcp "claude mcp get: cloudtrail"      bash -lc "claude mcp get awslabs.cloudtrail-mcp-server"
check_claude_mcp "claude mcp get: iam"             bash -lc "claude mcp get awslabs.iam-mcp-server"
check_claude_mcp "claude mcp get: context7"        bash -lc "claude mcp get context7"

### 結果 ###
if [ "$FAIL" -ne 0 ]; then
  echo "E2Eテスト: 失敗した項目があります"
  exit 1
fi
echo "E2Eテスト: 全項目成功"
