---
description: .claude/ 配下の書き込み保護仕様と運用ルール
globs: []
---

# `.claude/` 書き込み保護ルール

## Claude Code の `.claude/` 保護仕様

- `.claude/` 配下のファイルは `Edit`/`Write` の一般許可（allowedTools）では保護がバイパスされない
- `bypassPermissions` モードでも `.claude/` への書き込みには承認プロンプトが表示される
- **例外（保護なし）**: `.claude/commands/`, `.claude/agents/`, `.claude/skills/` は保護対象外

## バックグラウンドエージェントでの注意点

- `run_in_background: true` のエージェントが `.claude/` 配下を編集すると、承認プロンプトを受け付けられずスタックする
- 対策: パススコープ付き権限で必要なパスのみ明示的に許可する

## 推奨設定パターン

### 許可すべきパス

エージェントがルール更新等で編集する必要がある場合、以下のパススコープ付き権限を設定する:

- `Edit(.claude/rules/**)`
- `Write(.claude/rules/**)`
- `Edit(.claude/CLAUDE.md)`

### 保護を維持すべきパス

以下のファイルは意図しない変更を防ぐため、保護を維持する（明示的な許可を設定しない）:

- `.claude/settings.json` — プロジェクト全体の設定。不正な変更はセキュリティリスクになる
- `.claude/settings.local.json` — ローカル設定。個人の権限設定を含む
