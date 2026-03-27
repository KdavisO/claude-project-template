---
description: プロジェクト巡回によるIssue自動提案を実行します。
---

プロジェクトのコードベース、PR、Issue、ドキュメントを巡回・分析し、改善点やバグの可能性を検出してIssue候補を提案してください。

引数: `$ARGUMENTS`

## 引数の解析

- `code` → コード巡回のみ
- `pr` → PR巡回のみ
- `issue` → Issue巡回のみ
- `docs` → ドキュメント巡回のみ
- `all` または引数なし → すべての巡回対象を実行

複数指定可（例: `code pr`）

## 巡回フロー

### 準備: 既存オープンIssue一覧を取得（重複チェック用）

```bash
gh issue list --state open --json number,title,body,labels --limit 100
```

この一覧を以降の各巡回で「既存Issueとの重複チェック」に使用する。

### 巡回1: コード巡回（`code`）

以下の観点でリポジトリ内のソースコードを分析する:

1. **TODOコメント**: `TODO`, `FIXME`, `HACK`, `XXX` コメントを検索し、Issue化すべきものを検出
   ```bash
   grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" --include="*.py" --include="*.go" --include="*.rs" .
   ```
   ※ プロジェクトの技術スタックに合わせて対象拡張子を調整する。`.claude/` ディレクトリ配下は除外する。
2. **非推奨APIの使用**: deprecated な関数・メソッド・パッケージの使用箇所を検出
3. **セキュリティリスク**: ハードコードされた認証情報、安全でないHTTP通信、入力バリデーション不備等を検出
4. **パフォーマンス改善点**: N+1クエリパターン、不必要な再レンダリング、大きなバンドルサイズ等を検出
5. **エラーハンドリングの不備**: catch句が空、エラーの握りつぶし等を検出

### 巡回2: PR巡回（`pr`）

1. オープンPRを確認:
   ```bash
   gh pr list --state open --json number,title,body,labels,author,createdAt --limit 50
   ```
   - 長期間オープンのPR（14日以上）を検出
   - レビュー待ちのまま放置されているPRを検出

2. 最近マージされたPR（直近30日）を確認:
   ```bash
   gh pr list --state merged --json number,title,body,labels --limit 30
   ```
   - PR本文に残タスク（未チェックのチェックボックス `- [ ]`）があるものを検出
   - フォローアップが必要と明記されている項目を検出

### 巡回3: Issue巡回（`issue`）

1. 長期間オープンのIssue（30日以上）を検出:
   ```bash
   gh issue list --state open --json number,title,createdAt,labels,assignees --limit 100
   ```
   - 作成から30日以上経過し、アサインもラベルもないIssueを特定

2. 最近クローズされたIssueで再発の兆候を検出:
   ```bash
   gh issue list --state closed --json number,title,body,labels,closedAt --limit 50
   ```
   - `bug` ラベル付きでクローズされたIssueについて、関連するコード領域に最近の変更がないか確認

### 巡回4: ドキュメント巡回（`docs`）

1. **CLAUDE.md とコードの乖離**: `.claude/CLAUDE.md` に記載の技術スタック・重要ファイルが実際のプロジェクト構造と一致しているか確認
2. **rules/ の整合性**: `.claude/rules/` 配下のルールファイルが実際の運用と乖離していないか確認
3. **commands/ の網羅性**: `.claude/commands/` 配下のコマンドファイルが `settings.json` の description と整合しているか確認
4. **SETUP.md の記載漏れ**: 新しく追加されたコマンドやルールが SETUP.md の書き換え箇所一覧に反映されているか確認
5. **README等の更新漏れ**: README.md がある場合、記載内容とコードの乖離を確認

## 結果の出力フォーマット

各巡回の検出結果を以下のフォーマットでIssue候補として一覧表示する:

```
## 巡回結果

### コード巡回
| # | カテゴリ | 概要 | 重要度 | 既存Issue重複 |
|---|----------|------|--------|---------------|
| 1 | bug      | ... | high   | なし          |
| 2 | refactor | ... | medium | #XX と類似    |

### PR巡回
| # | カテゴリ | 概要 | 重要度 | 既存Issue重複 |
|---|----------|------|--------|---------------|
| 1 | chore    | ... | low    | なし          |

### Issue巡回
（同様のフォーマット）

### ドキュメント巡回
（同様のフォーマット）

---
検出件数: {合計}件（重複疑い: {重複数}件）
```

- **カテゴリ**: `bug`, `enhancement`, `refactor`, `documentation`, `chore` のいずれか
- **重要度**: `high`（セキュリティ・バグ）, `medium`（機能改善・パフォーマンス）, `low`（リファクタリング・ドキュメント）
- **既存Issue重複**: タイトルや内容が類似する既存オープンIssueがある場合にフラグ付け

## Issue作成の確認

検出結果を表示した後、ユーザーに確認を求める:

```
Issue化する候補の番号を指定してください（例: 1,3,5）。
`all` で全件、`none` でスキップ。重複フラグ付きは除外推奨。
```

- ユーザーが承認した候補のみ `/issue-create` でIssueを作成する
- **自動作成はしない** — 必ずユーザーの明示的な承認を得る
- 重複フラグ付きの候補をユーザーが選択した場合、重複の可能性がある旨を再度警告する

## 注意事項

- 巡回対象がない場合（例: PRが0件）、その巡回はスキップして「対象なし」と表示する
- 検出件数が0件の場合、「問題は検出されませんでした」と表示する
- GitHub API のレート制限に注意し、必要最小限のAPI呼び出しに抑える
- `.claude/` ディレクトリ配下のファイルはコード巡回の対象外とする（コマンド・ルールファイルはドキュメント巡回で扱う）
