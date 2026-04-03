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

# Claude Code をグローバルインストール
RUN npm install -g @anthropic-ai/claude-code

# 作業ユーザーを作成（root での実行を避ける）
RUN useradd -m -s /bin/bash claude
USER claude
WORKDIR /home/claude/workspace

# デフォルトコマンド: 完全自律モードで Claude Code を起動
ENTRYPOINT ["claude", "--dangerously-skip-permissions"]
