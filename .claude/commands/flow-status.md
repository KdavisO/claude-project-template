---
description: 実行中の自動フローの進捗状況を表示します。
---

実行中の `/issue-start --parallel --auto` フローの進捗を一覧表示してください。

## 手順

### 1. ステータスファイルの収集

`/tmp/{project}-flow-{ownerRepo}-*` パターンでステータスファイルを検索する:

```bash
ls /tmp/{project}-flow-{ownerRepo}-* 2>/dev/null
```

`{project}` はリポジトリのディレクトリ名（`basename $(git rev-parse --show-toplevel)` 等で取得）。`{ownerRepo}` は `gh repo view --json owner,name -q '.owner.login + "-" + .name'` で取得。

### 2. 各フローの情報を読み取り

各ステータスファイル（`/tmp/{project}-flow-{ownerRepo}-{issue番号}`）はJSON形式:

```json
{
  "issue": 123,
  "branch": "feat/123-example",
  "pr": 456,
  "phase": "polling",
  "worktree": "/path/to/worktree",
  "updated_at": "2026-03-25T00:00:00Z"
}
```

`phase` の値:
- `worktree`: worktree作成中
- `implementing`: 実装中
- `committing`: コミット中
- `pr-created`: PR作成済み
- `polling`: レビューポーリング中
- `reviewing`: レビュー対応中
- `post-action`: ポストアクション実行中
- `completed`: 完了（※ 完了時はファイル削除されるため通常は表示されない）
- `error`: エラーで停止

### 3. 補足情報の収集

まず `{ownerRepo}` を取得する:

```bash
gh repo view --json owner,name -q '.owner.login + "-" + .name'
```

各フローについて、追加情報を収集する:

- **ポーリング中の場合**: idle カウンターファイル（`/tmp/{project}-review-{ownerRepo}-idle-{PR番号}`）を読み、空振り回数を取得
- **cronタスク**: `CronList` で稼働中のポーリングタスクを確認
- **PR状態**: `gh pr view {PR番号} --json state -q .state` で現在のPR状態を確認
- **エラー時**: ステータスファイルの `error` フィールドからエラー内容を表示

### 4. 一覧表示

以下のフォーマットで出力:

```
## 自動フロー進捗状況

| Issue | ブランチ | PR | フェーズ | 詳細 | 最終更新 |
|-------|---------|-----|---------|------|---------|
| #123  | feat/123-example | #456 | ポーリング中 | 空振り 1/3 | 2分前 |
| #789  | fix/789-bug | - | 実装中 | - | 30秒前 |
```

フェーズの日本語表示:
- `worktree` → worktree作成中
- `implementing` → 実装中
- `committing` → コミット中
- `pr-created` → PR作成済み
- `polling` → ポーリング中
- `reviewing` → レビュー対応中
- `post-action` → ポストアクション中
- `completed` → 完了
- `error` → エラー停止

### 5. フローがない場合

ステータスファイルが見つからない場合:
「実行中の自動フローはありません」と出力

### 6. 古いステータスの警告

以下の基準で、停止している可能性のあるフローに警告を表示する:

- **`polling` 以外のフェーズ**: `updated_at` が30分以上前の場合、「このフローは30分以上更新されていません。停止している可能性があります」と警告
- **`polling` フェーズ**: idle カウンターファイルの最終更新時刻が30分以上前の場合にのみ警告（`polling` 中はレビュー着信がなくても状態遷移せず `updated_at` が更新されないため、cronタスクの生存確認として idle ファイルの更新時刻を使用する）
