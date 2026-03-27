# セットアップガイド

このテンプレートから新しいプロジェクトを作成した後、以下のファイルをプロジェクトに合わせて書き換えてください。

## 作成方法

```bash
gh repo create <new-repo> --template KdavisO/claude-project-template --public
```

## 書き換え箇所一覧

| ファイル                       | 書き換え箇所                                 | 説明                                                                             |
| ------------------------------ | -------------------------------------------- | -------------------------------------------------------------------------------- |
| `.claude/CLAUDE.md`                    | 全体                                         | プロジェクト概要・技術スタック・重要ファイル                                     |
| `.claude/settings.json`                | `Bash(pnpm *)` 等                            | パッケージマネージャに合わせて許可コマンド変更                                   |
| `.claude/commands/issue-create.md`     | ラベル候補                                   | プロジェクトのラベル分類に合わせる                                               |
| `.claude/commands/issue-start.md`      | `{project}-` プレフィックス                  | プロジェクト名に変更（worktreeディレクトリ名）                                   |
| `.claude/commands/issue-pr.md`         | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `.claude/commands/review-respond.md`   | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `.claude/commands/parallel-suggest.md` | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `.claude/rules/parallel-workflow.md`   | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `.claude/rules/git-conventions.md`     | `{github_username}`, reviewer                | assignee/reviewer を変更                                                         |
| `.claude/rules/project-structure.md`   | 全体                                         | プロジェクト構造に合わせて書き換え                                               |
| `.github/release.yml`                  | カテゴリ・ラベル                             | プロジェクトのラベルに合わせてリリースノートのカテゴリを変更                     |

**レビュワー名に関する注記:** `.claude/rules/git-conventions.md` ではassignee/reviewerの短縮名を、`.claude/commands/issue-pr.md` と `.claude/commands/review-respond.md` では正式名 `copilot-pull-request-reviewer[bot]` を使用しています。テンプレート展開時は、使用するレビュワーに合わせて**両方のファイル**を統一的に変更してください。

## 連続自動実行

`/issue-start` に `--continuous` フラグを追加することで、1つのIssueが完了した後に自動で次のIssueを選定・着手できます。

### 使い方

```bash
# 最大3件のIssueを連続処理（デフォルト）
/issue-start 28 --parallel --auto --continuous

# 最大5件のIssueを連続処理
/issue-start 28 --parallel --auto --continuous --max-issues 5
```

### 動作概要

1. 指定されたIssueを `--parallel --auto` モードで処理（実装→PR→レビュー→マージ／条件によりマージをスキップ）
2. フロー完了後、`/suggest-next` で次の候補Issueを自動選定
3. 競合チェック（worktree・オープンPR・アサイン）を通過した候補に対して自動着手
4. `--max-issues` の上限に達するか、候補がなくなるまで繰り返す

### 注意事項

- `--continuous` は `--parallel --auto` との併用が必須
- `--max-issues` のデフォルト値は3（暴走防止）
- エラー発生時は連続実行を停止し、ユーザーに報告
- 各Issue間の競合チェックは `/suggest-next` が自動で実施

## リリース・バージョン管理

テンプレートにはリリースノート自動作成とセマンティックバージョニングの仕組みが含まれています。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.github/release.yml` | GitHub 自動生成リリースノートのカテゴリ設定 |
| `.claude/commands/release.md` | `/release` コマンド（バージョンバンプ〜GitHub Release作成を一気通貫実行） |

### `/release` コマンドの使い方

```bash
/release              # コミットプレフィックスから自動でバンプ種別を判定
/release minor        # minor バンプを明示指定
/release --dry-run    # 実行内容のプレビューのみ（変更なし）
```

### カスタマイズ

- **リリースノートのカテゴリ**: `.github/release.yml` のラベルとカテゴリを編集
- **バージョンバンプルール**: `.claude/commands/release.md` の「バージョンバンプの種別を判定」セクションを編集
- **CHANGELOG フォーマット**: `.claude/commands/release.md` の「CHANGELOG.md を更新」セクションを編集

## skills/ ディレクトリ

`skills/` にはプロジェクト固有のスキルを配置します（例: Supabaseマイグレーション用スキル等）。テンプレートでは `.gitkeep` のみが含まれています。

## 書き換え手順

1. テンプレートからリポジトリを作成
2. 上記一覧に従い、プレースホルダ（`{project}-`, `{github_username}` 等）を実際の値に置換
3. `.claude/CLAUDE.md` にプロジェクト概要・技術スタックを記載
4. `.claude/rules/project-structure.md` にプロジェクト固有のルールを記載
5. 必要に応じて `.claude/skills/` にプロジェクト固有のスキルを追加
6. テンプレート同期を有効化（[docs/template-sync.md](docs/template-sync.md) 参照）:
   - `gh secret set TEMPLATE_SYNC_TOKEN` でテンプレート同期用PATを設定（必要な権限: Contents R/W, Pull requests R/W）
   - `.templatesyncignore` にプロジェクト固有ファイルを追加（例: `.claude/CLAUDE.md`, `.claude/settings.json`。詳細は [docs/template-sync.md](docs/template-sync.md) の該当セクションを参照）
   - `gh workflow run template-sync.yml` で動作確認
7. この `SETUP.md` は書き換え完了後に削除してOK
