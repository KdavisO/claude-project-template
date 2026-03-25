#!/bin/bash
# cleanup-shells.sh
# Claude Code のバックグラウンドシェルプロセスをクリーンアップする
#
# Claude Code は Bash ツール経由でシェルプロセスを起動するが、
# /clear 実行時にこれらのプロセスは自動終了されない。
# このスクリプトは Claude Code が起動した残存シェルプロセスを安全に終了する。

set -euo pipefail

# このスクリプトの祖先プロセス（PPID を遡って探索）から claude 実体のみを対象にする
CLAUDE_PIDS=""

CURRENT_PID="$$"
while :; do
  # 親 PID を取得
  PARENT_PID=$(ps -o ppid= -p "$CURRENT_PID" 2>/dev/null | tr -d '[:space:]')

  # 親が取得できない、または init(1) に到達したら終了
  if [ -z "$PARENT_PID" ] || [ "$PARENT_PID" = "1" ]; then
    break
  fi

  # 親プロセスのコマンドラインを取得
  PARENT_CMD=$(ps -o command= -p "$PARENT_PID" 2>/dev/null || true)

  # コマンドラインに "claude" を含むプロセスを Claude Code 実体とみなす
  if printf '%s\n' "$PARENT_CMD" | grep -q "claude"; then
    CLAUDE_PIDS="$PARENT_PID"
    break
  fi

  # さらに上位の親プロセスへ
  CURRENT_PID="$PARENT_PID"
done

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
      # 少し待機して終了したか確認
      sleep 0.5
      if kill -0 "$CHILD_PID" 2>/dev/null; then
        # まだ生きている場合は再度 SIGTERM を送る
        kill -TERM "$CHILD_PID" 2>/dev/null || true
        sleep 0.5
      fi
      # それでも生存している場合は SIGKILL で強制終了
      if kill -0 "$CHILD_PID" 2>/dev/null; then
        kill -KILL "$CHILD_PID" 2>/dev/null || true
        sleep 0.1
      fi
      # 最終的にプロセスが存在しない場合のみカウントを増やす
      if ! kill -0 "$CHILD_PID" 2>/dev/null; then
        KILLED_COUNT=$((KILLED_COUNT + 1))
      fi
    fi
  done
done

if [ "$KILLED_COUNT" -gt 0 ]; then
  echo "${KILLED_COUNT} 個のバックグラウンドシェルプロセスを終了しました。"
else
  echo "クリーンアップ対象のシェルプロセスはありません。"
fi
