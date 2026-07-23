#!/usr/bin/env bash
# DevContainer 初回作成時のセットアップ: Kiro CLI のインストール
set -euo pipefail

# volumeマウントされたディレクトリの所有者を修正
sudo chown -R "$(id -u):$(id -g)" "$HOME/.kiro" "$HOME/.local" "$HOME/.aws" "$HOME/.claude" 2>/dev/null || true

if command -v kiro-cli >/dev/null 2>&1; then
  echo "kiro-cli は既にインストール済み: $(kiro-cli --version || true)"
  exit 0
fi

# アーキテクチャ判定（Apple Silicon = aarch64 / Intel・AMD = x86_64）
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)  PKG="kirocli-x86_64-linux.zip" ;;
  aarch64) PKG="kirocli-aarch64-linux.zip" ;;
  *) echo "未対応アーキテクチャ: $ARCH" >&2; exit 1 ;;
esac

TMPDIR_KIRO="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_KIRO"' EXIT
cd "$TMPDIR_KIRO"

echo "Kiro CLI をダウンロード中 ($PKG)..."
curl --proto '=https' --tlsv1.2 -sSf \
  --retry 5 --retry-delay 3 --retry-connrefused --retry-all-errors \
  "https://desktop-release.q.us-east-1.amazonaws.com/latest/${PKG}" -o kirocli.zip
unzip -q kirocli.zip
./kirocli/install.sh --no-confirm || ./kirocli/install.sh

# ~/.local/bin にインストールされるため PATH を確認
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi


# terraform-mcp-server (Go製、旧awslabs製uvxパッケージはyank済みのため後継に移行)
# https://github.com/hashicorp/terraform-mcp-server
if ! command -v terraform-mcp-server >/dev/null 2>&1; then
  echo "terraform-mcp-server をインストール中..."
  GOBIN="$HOME/.local/bin" go install github.com/hashicorp/terraform-mcp-server/cmd/terraform-mcp-server@latest
fi


# github-mcp-server (Go製、Docker-in-Docker回避のためgo installで導入)
# https://github.com/github/github-mcp-server
if ! command -v github-mcp-server >/dev/null 2>&1; then
  echo "github-mcp-server をインストール中..."
  GOBIN="$HOME/.local/bin" go install github.com/github/github-mcp-server/cmd/github-mcp-server@latest
fi

echo "セットアップ完了。ターミナルを開き直して 'kiro-cli login' を実行してください。"
