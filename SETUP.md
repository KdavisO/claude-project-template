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
| `.claude/settings.json`                | `Bash(pnpm *)` 等、`env` セクション          | パッケージマネージャに合わせて許可コマンド変更、Agent Teams有効化設定、LSPプラグイン設定 |
| `.claude/commands/issue-create.md`     | ラベル候補                                   | プロジェクトのラベル分類に合わせる                                               |
| `.claude/commands/issue-start.md`      | `{project}-` プレフィックス                  | プロジェクト名に変更（worktreeディレクトリ名）                                   |
| `.claude/commands/issue-pr.md`         | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `.claude/commands/review-respond.md`   | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `.claude/commands/parallel-suggest.md` | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `.claude/rules/parallel-workflow.md`   | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `.claude/rules/git-conventions.md`     | `{github_username}`, reviewer                | assignee/reviewer を変更                                                         |
| `.claude/rules/project-structure.md`   | 全体                                         | プロジェクト構造に合わせて書き換え                                               |
| `.github/release.yml`                  | カテゴリ・ラベル                             | プロジェクトのラベルに合わせてリリースノートのカテゴリを変更                     |
| `.claudeignore`                        | 除外パターン                                 | プロジェクトの技術スタックに合わせて不要なパターンを削除・追加                   |

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
- `--max-issues` のデフォルト値は3（暴走防止）。現在のIssueを含む総数（例: `--max-issues 3` で最大3件処理）
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

## プロジェクト巡回（`/patrol`）

テンプレートにはプロジェクトの改善点を自動検出するための巡回コマンドが含まれています。

### 概要

`/patrol` はコードベース、PR、Issue、ドキュメントを巡回・分析し、改善点やバグの可能性を検出してIssue候補として提案します。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.claude/commands/patrol.md` | `/patrol` コマンド定義（巡回フロー・出力フォーマット） |

### 巡回対象

| 対象 | 説明 |
| --- | --- |
| `code` | TODOコメント、非推奨API、セキュリティリスク、パフォーマンス改善点、エラーハンドリングの不備 |
| `pr` | 長期間オープンPR、マージ済みPRの残タスク・フォローアップ |
| `issue` | 長期間オープンのIssue、クローズ済みバグの再発兆候 |
| `docs` | CLAUDE.md・rules・commands とコードの乖離、SETUP.md の記載漏れ |
| `all` | すべての巡回対象をまとめて実行（引数なしと同等） |

### 使い方

```bash
/patrol              # すべての巡回対象を実行
/patrol all          # all トークンを指定してすべての巡回対象を実行
/patrol code pr      # コードとPRのみ巡回
/patrol docs         # ドキュメントのみ巡回
/patrol --team       # Agent Teams モードですべて巡回（巡回対象ごとにチームメイトを並列分担）
/patrol all --team   # Agent Teams モードで all（すべての巡回対象）を巡回
/patrol code pr --team  # Agent Teams モードでコード・PRを巡回
```

> **注**: `--team` フラグは Agent Teams（実験的機能）の有効化が必要です。詳細は後述の「[Agent Teams（実験的機能）](#agent-teams実験的機能)」セクションを参照してください。

### カスタマイズ

- **巡回観点の追加・変更**: `.claude/commands/patrol.md` の各巡回セクションを編集
- **出力フォーマット**: `.claude/commands/patrol.md` の「結果の出力フォーマット」セクションを編集
- **コード巡回の対象拡張子**: `.claude/commands/patrol.md` の `grep` コマンドの `--include` オプションをプロジェクトの技術スタックに合わせて調整
- **Issue化フロー**: `.claude/commands/patrol.md` の「Issue作成の確認」セクションを編集

### 出力とIssue化フロー

巡回結果はカテゴリ（bug, enhancement, refactor, documentation, chore）・重要度（high/medium/low）・既存Issue重複チェック付きの一覧表として出力されます。検出された候補からIssue化するものをユーザーが選択し、`/issue-create` で個別にIssueを作成します。詳細は `.claude/commands/patrol.md` の「結果の出力フォーマット」「Issue作成の確認」セクションを参照してください。

## Agent Teams（実験的機能）

テンプレートには Agent Teams の有効化設定とガイドラインが含まれています。

### 概要

Agent Teams は複数のチームメイト（専門的な役割を持つエージェント）が協調してタスクを遂行する実験的機能です。従来のサブエージェント + worktree パターンに加え、相互依存のあるタスクの並列実行やレビューコメントの観点別分担処理が可能になります。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.claude/settings.json` | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 環境変数の設定 |
| `.claude/rules/agent-teams.md` | Agent Teams の利用ガイドライン（サブエージェントとの使い分け） |
| `.claude/rules/parallel-workflow.md` | Agent Teams パターンの追加セクション |
| `.claude/commands/review-respond.md` | `--team` フラグによる Agent Teams モード（レビュー対応） |
| `.claude/commands/patrol.md` | `--team` フラグによる Agent Teams モード（巡回分担） |
| `.claude/commands/issue-start.md` | `--team` フラグによる自動フローでの Agent Teams 伝播 |
| `.claude/commands/issue-pr.md` | `--team` フラグによる `/review-respond` への Agent Teams 伝播 |

### セットアップ

1. `.claude/settings.json` に `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が設定済み（テンプレートに含まれる）
2. 無効化する場合は `.claude/settings.json` の `env` セクションから該当行を削除

### カスタマイズ

- **チームメイトの役割**: `.claude/rules/agent-teams.md` のチームメイト作成例を編集
- **レビュー分担の閾値**: `.claude/commands/review-respond.md` の「5件以上」の閾値を調整
- **表示モード**: `.claude/settings.json` に `"teammateMode": "auto"` / `"in-process"` / `"tmux"` を追加
- **並列パターン**: `.claude/rules/parallel-workflow.md` の Agent Teams パターンを編集

### 使い方の例

```bash
# レビュー対応でAgent Teamsを使用
/review-respond --team 123

# 自動モードとAgent Teamsの併用
/review-respond --auto --team

# 巡回でAgent Teamsを使用（巡回対象ごとにチームメイトを並列分担）
/patrol --team
/patrol code pr --team

# 自動フローでAgent Teamsを使用（レビュー対応時に--teamが伝播）
/issue-start 38 --parallel --auto --team

# 連続自動実行でもAgent Teamsを使用（次Issue着手時にも--teamを引き継ぐ）
/issue-start 38 --parallel --auto --continuous --team

# 手動でAgent Teamsを作成（任意のタスク）
# プロンプトで直接リクエスト:
# 「3つのチームメイトを作成して、コード品質・セキュリティ・テストの観点でレビューしてください」
```

### 注意事項

- Agent Teams は実験的機能であり、動作が不安定な場合があります
- 1セッションにつき1チームのみ作成可能
- セッション復元（`/resume`）でチームメイトは復元されません
- 詳細は `.claude/rules/agent-teams.md` を参照

## PreToolUse プロンプト強化フック（オプション）

Claude Code の PreToolUse フックを使うと、ツール呼び出しの直前にカスタムスクリプトを実行できます。これを利用して、曖昧なプロンプトを自動で詳細な指示にリライトする仕組みを導入できます。

### 仕組み

PreToolUse フックは `.claude/settings.json` の `hooks.PreToolUse` セクションで設定します。ツール呼び出しが実行される前にフックが起動し、プロンプトの明瞭さを評価・改善した結果を返すことで、より正確な応答を得られます。

### コミュニティツール: claude-code-prompt-improver

[severity1/claude-code-prompt-improver](https://github.com/severity1/claude-code-prompt-improver) は、PreToolUse フックとして動作するプロンプト強化ツールです。

**インストール手順:**

```bash
# リポジトリをクローン
git clone https://github.com/severity1/claude-code-prompt-improver.git
cd claude-code-prompt-improver

# 依存関係をインストール（ローカル端末で実行）
pnpm install
```

**settings.json への設定例:**

既存の `.claude/settings.json` には `hooks.SessionEnd` などの設定が含まれている場合があります。以下は `hooks` オブジェクト内に `PreToolUse` を追記する例です。既存の `hooks` エントリを上書きしないよう注意してください。

`matcher` はフックを適用するツール名のパターンを指定します（例: `"Task"` は TaskCreate/TaskUpdate 等のツール呼び出しにマッチ）。すべてのツールに適用する場合は `matcher` を省略するか `"*"` を指定してください。`command` にはクローンしたリポジトリ内のスクリプトの絶対パスを指定します:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Task",
        "hooks": [
          {
            "type": "command",
            "command": "node /path/to/claude-code-prompt-improver/index.js"
          }
        ]
      }
    ]
  }
}
```

> **注意:** このツールは外部のコミュニティプロジェクトであり、テンプレートの必須要件ではありません。`PreToolUse` フックで外部ツールのコマンドを実行すると、プロンプト内容や作業ディレクトリの情報が外部コードに渡る可能性があります。導入はユーザーの判断に委ねますが、利用前に実行内容を監査し、参照するコードはコミット固定し、必要権限や外部通信の有無・送信内容を確認してください。`matcher` やコマンドパスはプロジェクトの要件に合わせて調整してください。

### 参考

- [Anthropic コンソール プロンプト改善ツール](https://console.anthropic.com/) — 公式のプロンプト最適化機能
- [Claude Code Hooks ドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks)

## カスタムサブエージェント（agents/）

`.claude/agents/` にはカスタムサブエージェントの定義ファイルを配置します。サブエージェントを使うと、外部ツール（Gemini CLI 等）をラップして大規模解析を Claude Code から委任できます。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.claude/agents/gemini-analyzer.md` | Gemini CLI を使った大規模コードベース解析のサンプルエージェント |

### エージェント定義の構造

エージェント定義ファイルは Markdown 形式で、以下のフロントマターを含みます:

```yaml
---
name: エージェント名
description: エージェントの説明（Agent ツールの description に表示される）
model: sonnet  # 使用するモデル（省略可）
tools:         # エージェントが使用できるツール
  - Bash
  - Read
  - Glob
  - Grep
---
```

フロントマター以降にエージェントへのシステムプロンプト（役割、手順、注意事項等）を記述します。

### 使い方

```
# Agent ツールで直接呼び出し
Agent(subagent_type="gemini-analyzer", prompt="src/ 配下の全 TypeScript ファイルのアーキテクチャを分析してください")
```

### カスタマイズ

- **新しいエージェントの追加**: `.claude/agents/` に新しい `.md` ファイルを作成
- **既存エージェントの編集**: フロントマターのツール一覧やシステムプロンプトを変更
- **モデルの変更**: `model` フィールドで `sonnet`, `opus`, `haiku` を指定
- **外部ツールの前提条件**: エージェントが依存する外部ツール（Gemini CLI 等）のインストール手順をエージェント定義内に記載

### 注意事項

- サンプルエージェント（`gemini-analyzer.md`）は外部ツール（Gemini CLI）への依存があるため、利用前にインストールが必要です
- downstream プロジェクトではプロジェクト固有のエージェントに置き換えることを想定しています

## skills/ ディレクトリ

`skills/` にはプロジェクト固有のスキルを配置します（例: Supabaseマイグレーション用スキル等）。テンプレートでは `.gitkeep` のみが含まれています。

## LSP プラグイン

テンプレートには Claude Code の LSP（Language Server Protocol）プラグインの有効化設定が含まれています。

### 概要

LSP プラグインを有効にすると、Claude Code がテキストベースの grep 検索に代わり、IDE と同等のコードインテリジェンス（定義ジャンプ、参照検索、リアルタイム診断等）を利用できるようになります。

### 含まれる設定

| ファイル | 設定内容 |
| --- | --- |
| `.claude/settings.json` | `env` セクションの `"ENABLE_LSP_TOOL": "1"` |

### プラグインのインストール

LSP プラグインはコミュニティマーケットプレイスから入手できます:

```bash
claude mcp add --transport stdio lsp -- npx @anthropic-ai/claude-code-lsp@latest
```

参考: [Piebald-AI/claude-code-lsps](https://github.com/Piebald-AI/claude-code-lsps)

### 対応言語

- TypeScript / JavaScript
- Python
- Ruby
- Go
- Rust
- Java
- C / C++
- その他、Language Server が利用可能な言語

### 無効化する場合

`.claude/settings.json` の `env` セクションから `ENABLE_LSP_TOOL` を削除するか、値を `"0"` に変更してください:

```json
{
  "env": {
    "ENABLE_LSP_TOOL": "0"
  }
}
```

## 書き換え手順

1. テンプレートからリポジトリを作成
2. 上記一覧に従い、プレースホルダ（`{project}-`, `{github_username}` 等）を実際の値に置換
3. `.claude/CLAUDE.md` にプロジェクト概要・技術スタックを記載
4. `.claude/rules/project-structure.md` にプロジェクト固有のルールを記載
5. 必要に応じて `.claude/skills/` にプロジェクト固有のスキルを追加
6. テンプレート同期を有効化（[docs/template-sync.md](docs/template-sync.md) 参照）:
   - `gh secret set TEMPLATE_SYNC_TOKEN` でテンプレート同期用PATを設定（必要な権限: Contents R/W, Pull requests R/W）
   - `.templatesyncignore` にプロジェクト固有ファイルを追加（例: `.claude/CLAUDE.md`, `.claude/settings.json`）。`.claudeignore` をカスタマイズする場合はダウンストリーム側の `.templatesyncignore` にも `.claudeignore` を追加すること（テンプレート側の `.templatesyncignore` は同期されないため）。詳細は [docs/template-sync.md](docs/template-sync.md) の該当セクションを参照
   - `gh workflow run template-sync.yml` で動作確認
7. この `SETUP.md` は書き換え完了後に削除してOK
