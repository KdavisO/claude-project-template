#!/bin/bash
# cleanup-shells.sh
# Claude Code のバックグラウンドシェルプロセスをクリーンアップする
#
# Claude Code は Bash ツール経由でシェルプロセスを起動するが、
# /clear 実行時にこれらのプロセスは自動終了されない。
# このスクリプトは Claude Code が起動した残存シェルプロセスを安全に終了する。

set -euo pipefail

# Claude Code の親プロセスを特定
# claude プロセスの子プロセスとして起動されたシェルを対象にする
CLAUDE_PIDS=$(pgrep -f "claude" 2>/dev/null | grep -v "$$" || true)

if [ -z "$CLAUDE_PIDS" ]; then
  echo "Claude Code プロセスが見つかりません。"
  exit 0
fi

KILLED_COUNT=0

for CLAUDE_PID in $CLAUDE_PIDS; do
  # Claude プロセスの子シェルプロセスを取得
  CHILD_SHELLS=$(pgrep -P "$CLAUDE_PID" -f "(bash|zsh|sh)" 2>/dev/null || true)

  for CHILD_PID in $CHILD_SHELLS; do
    # 自分自身のプロセスツリーは除外
    if [ "$CHILD_PID" = "$$" ]; then
      continue
    fi

    # プロセスの状態を確認（実行中のものだけ対象）
    if kill -0 "$CHILD_PID" 2>/dev/null; then
      # まず SIGTERM で丁寧に終了を要求
      kill -TERM "$CHILD_PID" 2>/dev/null || true
      KILLED_COUNT=$((KILLED_COUNT + 1))
    fi
  done
done

if [ "$KILLED_COUNT" -gt 0 ]; then
  echo "${KILLED_COUNT} 個のバックグラウンドシェルプロセスを終了しました。"
else
  echo "クリーンアップ対象のシェルプロセスはありません。"
fi
