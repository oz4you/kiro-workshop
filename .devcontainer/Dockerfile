FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# IaC開発に必要な基本パッケージ
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
       unzip curl ca-certificates git jq less groff \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# trivy（IaCセキュリティスキャン）
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
    | sh -s -- -b /usr/local/bin

# uv/uvx（MCPサーバ実行用）
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh
