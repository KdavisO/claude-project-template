# セットアップガイド

このテンプレートから新しいプロジェクトを作成した後、以下のファイルをプロジェクトに合わせて書き換えてください。

## 作成方法

```bash
gh repo create <new-repo> --template KdavisO/claude-project-template --public
```

## 書き換え箇所一覧

| ファイル                       | 書き換え箇所                                 | 説明                                                                             |
| ------------------------------ | -------------------------------------------- | -------------------------------------------------------------------------------- |
| `CLAUDE.md`                    | 全体                                         | プロジェクト概要・技術スタック・重要ファイル                                     |
| `settings.json`                | `Bash(pnpm *)` 等                            | パッケージマネージャに合わせて許可コマンド変更                                   |
| `commands/issue-create.md`     | ラベル候補                                   | プロジェクトのラベル分類に合わせる                                               |
| `commands/issue-start.md`      | `{project}-` プレフィックス                  | プロジェクト名に変更（worktreeディレクトリ名）                                   |
| `commands/issue-pr.md`         | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `commands/review-respond.md`   | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `commands/parallel-suggest.md` | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `rules/parallel-workflow.md`   | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `rules/git-conventions.md`     | `{github_username}`, reviewer                | assignee/reviewer を変更                                                         |
| `rules/project-structure.md`   | 全体                                         | プロジェクト構造に合わせて書き換え                                               |

**レビュワー名に関する注記:** `rules/git-conventions.md` ではassignee/reviewerの短縮名を、`commands/issue-pr.md` と `commands/review-respond.md` では正式名 `copilot-pull-request-reviewer[bot]` を使用しています。テンプレート展開時は、使用するレビュワーに合わせて**両方のファイル**を統一的に変更してください。

## skills/ ディレクトリ

`skills/` にはプロジェクト固有のスキルを配置します（例: Supabaseマイグレーション用スキル等）。テンプレートでは `.gitkeep` のみが含まれています。

## 書き換え手順

1. テンプレートからリポジトリを作成
2. 上記一覧に従い、プレースホルダ（`{project}-`, `{github_username}` 等）を実際の値に置換
3. `CLAUDE.md` にプロジェクト概要・技術スタックを記載
4. `rules/project-structure.md` にプロジェクト固有のルールを記載
5. 必要に応じて `skills/` にプロジェクト固有のスキルを追加
6. テンプレート同期を有効化（[docs/template-sync.md](docs/template-sync.md) 参照）:
   - `gh secret set TEMPLATE_SYNC_TOKEN` でPATを設定
   - `.templatesyncignore` にプロジェクト固有ファイルを追加
   - `gh workflow run template-sync` で動作確認
7. この `SETUP.md` は書き換え完了後に削除してOK
