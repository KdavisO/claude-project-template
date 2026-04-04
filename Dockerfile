# Claude Code 自律実行環境
# Docker コンテナ内で --dangerously-skip-permissions を安全に使用するための環境

FROM node:22-slim

# 必要なシステムツールをインストール
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Claude Code をグローバルインストール（バージョン指定可能）
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}"

# 作業ユーザーを作成（root での実行を避ける）
# UID/GID をビルド引数で指定可能（CI 環境でホスト側と合わせる用途）
ARG UID=1000
ARG GID=1000
RUN groupadd -g "${GID}" claude && useradd -m -s /bin/bash -u "${UID}" -g "${GID}" claude
USER claude
WORKDIR /home/claude/workspace

# デフォルトコマンド: 完全自律モードで Claude Code を起動
ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
