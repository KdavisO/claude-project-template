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
  # 親 PID を取得（pipefail 下で ps 失敗時にスクリプトが中断しないよう || true）
  PARENT_PID=$(ps -o ppid= -p "$CURRENT_PID" 2>/dev/null | tr -d '[:space:]' || true)

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
TARGET_PIDS=""

for CLAUDE_PID in $CLAUDE_PIDS; do
  # Claude プロセスの子シェルプロセスを取得（実行ファイル名に厳密一致）
  for SHELL_NAME in bash zsh sh; do
    CHILD_SHELLS=$(pgrep -P "$CLAUDE_PID" -x "$SHELL_NAME" 2>/dev/null || true)
    for CHILD_PID in $CHILD_SHELLS; do
      # 自分自身のプロセスツリーは除外
      if [ "$CHILD_PID" = "$$" ]; then
        continue
      fi
      TARGET_PIDS="$TARGET_PIDS $CHILD_PID"
    done
  done
done

# 対象PIDがなければ終了
TARGET_PIDS=$(echo "$TARGET_PIDS" | tr -s ' ' | sed 's/^ //')
if [ -z "$TARGET_PIDS" ]; then
  echo "クリーンアップ対象のシェルプロセスはありません。"
  exit 0
fi

# 一括で SIGTERM を送信
for PID in $TARGET_PIDS; do
  kill -TERM "$PID" 2>/dev/null || true
done

# 1秒待機して残存プロセスを確認
sleep 1

# 残存プロセスに SIGKILL を送信
for PID in $TARGET_PIDS; do
  if kill -0 "$PID" 2>/dev/null; then
    kill -KILL "$PID" 2>/dev/null || true
  fi
done

sleep 0.1

# 終了確認・カウント
for PID in $TARGET_PIDS; do
  if ! kill -0 "$PID" 2>/dev/null; then
    KILLED_COUNT=$((KILLED_COUNT + 1))
  fi
done

if [ "$KILLED_COUNT" -gt 0 ]; then
  echo "${KILLED_COUNT} 個のバックグラウンドシェルプロセスを終了しました。"
else
  echo "クリーンアップ対象のシェルプロセスはありません。"
fi
