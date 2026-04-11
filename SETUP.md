# セットアップガイド

このテンプレートから新しいプロジェクトを作成した後、以下のファイルをプロジェクトに合わせて書き換えてください。

## 作成方法

```bash
gh repo create <new-repo> --template KdavisO/claude-project-template --public
```

## 書き換え箇所一覧

| ファイル                       | 書き換え箇所                                 | 説明                                                                             |
| ------------------------------ | -------------------------------------------- | -------------------------------------------------------------------------------- |
| `.claude/CLAUDE.md`                    | 全体                                         | プロジェクト概要・技術スタック・仕様書参照・重要ファイル                         |
| `.claude/settings.json`                | `Bash(pnpm *)` 等、`env` セクション          | パッケージマネージャに合わせて許可コマンド変更、Agent Teams有効化設定、LSPプラグイン設定 |
| `.mcp.json`                            | `mcpServers` セクション                      | MCP サーバーの追加・削除（Context7 等）                                          |
| `.claude/commands/issue-create.md`     | ラベル候補                                   | プロジェクトのラベル分類に合わせる                                               |
| `.claude/commands/issue-start.md`      | `{project}-` プレフィックス                  | プロジェクト名に変更（worktreeディレクトリ名）                                   |
| `.claude/commands/issue-pr.md`         | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `.claude/commands/review-respond.md`   | `{project}-review-` 一時ファイルパス         | プロジェクト名に変更                                                             |
| `.claude/commands/parallel-suggest.md` | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `.claude/rules/parallel-workflow.md`   | `docs/issue-groups.md` 参照                  | プロジェクトのIssueグループに合わせる                                            |
| `.claude/rules/git-conventions.md`     | `{github_username}`, reviewer                | assignee/reviewer を変更                                                         |
| `.claude/rules/project-structure.md`   | 全体                                         | プロジェクト構造に合わせて書き換え                                               |
| `.claude/rules/reactive-hooks.md`      | ユースケース・スクリプト例                   | プロジェクトのディレクトリ構成・環境管理方法に合わせる                           |
| `.claude/rules/quality-gate-hooks.md`  | lint・型チェックコマンド、タイムアウト値     | プロジェクトの lint/型チェック設定に合わせてカスタマイズ                          |
| `.github/release.yml`                  | カテゴリ・ラベル                             | プロジェクトのラベルに合わせてリリースノートのカテゴリを変更                     |
| `.claudeignore`                        | 除外パターン                                 | プロジェクトの技術スタックに合わせて不要なパターンを削除・追加                   |
| `.github/copilot-instructions.md`      | Focus Areas・Skip These                      | プロジェクトのレビュー方針・セキュリティ要件に合わせてカスタマイズ               |
| `.env.sample`                          | 環境変数エントリ                             | プロジェクト固有の環境変数を追記（テンプレート同期では上書きされない）           |

**レビュワー名に関する注記:** `.claude/rules/git-conventions.md` ではassignee/reviewerの短縮名を、`.claude/commands/issue-pr.md` と `.claude/commands/review-respond.md` では正式名 `copilot-pull-request-reviewer[bot]` を使用しています。テンプレート展開時は、使用するレビュワーに合わせて**両方のファイル**を統一的に変更してください。

## 環境変数（`.env.sample` → `.env`）

テンプレートには MCP サーバー用の環境変数をまとめた `.env.sample` が同梱されています。新しくテンプレートからプロジェクトを作成したら、以下の手順で `.env` を作成してください。

```bash
# 1. サンプルをコピー
cp .env.sample .env

# 2. .env を編集して実際のキーを設定
#    - BRAVE_API_KEY   （Brave Search MCP 用。https://brave.com/search/api/ から取得）
#    - OPENAI_API_KEY  （o3-search-mcp 用。OpenAI Tier 4 以上）
#    - 必要に応じて SEARCH_CONTEXT_SIZE / REASONING_EFFORT

# 3. .env を Git 管理対象から外す（未登録の場合のみ）
echo '.env' >> .gitignore
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  git rm --cached .env
fi
```

> **注意:** `.env` に値を書くだけでは Claude Code / MCP サーバーに自動では渡りません。通常は Claude Code 起動前に `export KEY=...` を実行するか、`direnv` などで `.env` を環境変数へロードしてから起動してください。詳細は後述の各 MCP サーバーセクション（Brave Search MCP / o3-search-mcp）を参照してください。

### テンプレート同期との関係

`.env.sample` は `.templatesyncignore` に登録されているため、テンプレート同期では上書きされません。これは下流プロジェクトが独自に追記した環境変数エントリを保護するための仕様です。

- **初回のテンプレート利用時:** `.env.sample` はテンプレートから配布されます（`gh repo create --template` 経由でコピーされる）
- **2回目以降のテンプレート同期時:** `.env.sample` は同期対象外となり、下流プロジェクトの独自エントリが保持されます
- **テンプレート側に新しい環境変数が追加された場合:** 下流プロジェクト側で手動マージが必要です。テンプレートのリリースノートや CHANGELOG を確認し、必要なキーを `.env.sample` / `.env` に追記してください

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

## Context7 MCP サーバー（オプション）

テンプレートには [Context7 MCP](https://github.com/upstash/context7) サーバーの設定が `.mcp.json` に含まれています。Context7 はライブラリの最新ドキュメントを LLM コンテキストに動的注入し、古い学習データに基づく API 誤用を防ぎます。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.mcp.json` | Context7 MCP サーバーの設定 |

### 動作確認

Claude Code セッション内で Context7 のツールが利用可能か確認:

```text
# セッション内で以下のようにライブラリドキュメントを参照できる
resolve-library-id で React のドキュメントを検索して
```

### 無効化する場合

`.mcp.json` から `context7` エントリを削除してください（他の MCP サーバー設定がある場合はそれらを残します）:

```json
{
  "mcpServers": {
    "other-server": {
      "command": "npx",
      "args": ["-y", "@example/other-mcp-server"]
    }
  }
}
```

### 注意事項

- Context7 がインデックスしていないマイナーライブラリには機能しない場合があります
- `npx` による初回起動時にパッケージのダウンロードが発生します
- Node.js（v18 以上）が必要です

## Brave Search MCP サーバー（オプション）

テンプレートには [Brave Search MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search) サーバーの設定が `.mcp.json` に含まれています。Brave Search は Web 検索 API を MCP 経由で Claude Code から直接利用でき、エラー解決や API 仕様確認などの軽量な検索に適しています。月 2,000 クエリまで無料で利用可能です。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.mcp.json` | Brave Search MCP サーバーの設定（`brave-search` エントリ） |
| `.claude/rules/web-delegation.md` | Brave Search MCP と gemini-analyzer の使い分け基準 |

### 前提条件

Brave Search API キーが必要です。以下の手順で取得・設定してください:

1. [Brave Search API](https://brave.com/search/api/) にアクセスし、アカウントを作成
2. 「Free」プラン（月 2,000 クエリ無料）を選択
3. API キーを取得
4. 環境変数 `BRAVE_API_KEY` にキーを設定:

> **注意:** `.env` に追記しただけでは、Claude Code のプロセスがその `.env` を自動ロードしない限り、Brave Search MCP サーバーには渡りません。テンプレートの `.claude/settings.json` には `.env` 読み込み hook はデフォルトで含まれていないため、通常は **Claude Code を起動する前に** `export BRAVE_API_KEY=...` を実行してください。`.env` を使う方法は、`direnv` や独自 hook などで起動前に環境変数へロードされる構成の場合に限ります。

```bash
# 推奨: Claude Code を起動する前に現在のシェルで設定
export BRAVE_API_KEY="your-api-key-here"

# .env を使う場合は、direnv / hooks 等で Claude Code 起動前に
# この値が環境変数としてロードされるようにしておく
echo 'BRAVE_API_KEY=your-api-key-here' >> .env

# 重要: .env は Git にコミットしない
echo '.env' >> .gitignore

# すでに .env を Git 管理している場合は追跡対象から外す
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  git rm --cached .env
fi
```

### 動作確認

Claude Code セッション内で Brave Search MCP のツール `brave_web_search` が利用可能か確認:

```text
# セッション内で brave_web_search を使って Web 検索を実行する例
brave_web_search で Next.js App Router middleware を検索して
```

### 使い分け

| 用途 | 手段 |
| --- | --- |
| 軽い検索（エラー解決、API仕様確認、単発の事実確認） | Brave Search MCP |
| 推論付き検索（技術比較、根本原因分析、設計判断） | o3-search-mcp |
| 大規模調査（網羅的スキャン、複数観点の調査） | gemini-analyzer |

詳細は `.claude/rules/web-delegation.md` を参照してください。

### 無効化する場合

`.mcp.json` から `brave-search` エントリを削除してください（他の MCP サーバー設定はそのまま残します）。

### 注意事項

- 無料プランは月 2,000 クエリの制限があります。上限を超えた場合は API エラーが返されます
- `BRAVE_API_KEY` 環境変数が未設定の場合、MCP サーバーの起動に失敗します
- `npx` による初回起動時にパッケージのダウンロードが発生します
- Node.js（v18 以上）が必要です

## o3-search-mcp サーバー（オプション）

テンプレートには [o3-search-mcp](https://github.com/yoshiko-pg/o3-search-mcp) サーバーの設定が `.mcp.json` に含まれています。OpenAI o3 の推論能力を活用した Web 検索を MCP 経由で Claude Code から実行でき、技術比較調査やエラーの根本原因分析など、単純検索では解決しない複雑な検索に適しています。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.mcp.json` | o3-search-mcp サーバーの設定（`o3-search` エントリ） |
| `.claude/rules/web-delegation.md` | Brave Search MCP / o3-search-mcp / gemini-analyzer の3段階使い分け基準 |

### 前提条件

OpenAI API キー（**Tier 4 以上**）が必要です。以下の手順で取得・設定してください:

1. [OpenAI Platform](https://platform.openai.com/) にアクセスし、アカウントを作成
2. API キーを取得（Tier 4 以上の API アクセスが必要。Tier 確認: [Usage Tiers](https://platform.openai.com/docs/guides/rate-limits/usage-tiers)）
3. 環境変数 `OPENAI_API_KEY` にキーを設定:

> **注意:** `.env` に追記しただけでは、Claude Code のプロセスがその `.env` を自動ロードしない限り、o3-search-mcp サーバーには渡りません。通常は **Claude Code を起動する前に** `export OPENAI_API_KEY=...` を実行してください。

```bash
# 推奨: Claude Code を起動する前に現在のシェルで設定
export OPENAI_API_KEY="your-api-key-here"
```

### 設定パラメータ

環境変数で以下のパラメータを調整できます（未設定時はデフォルト値 `medium` が使用されます）:

| 環境変数 | デフォルト | 説明 |
| --- | --- | --- |
| `SEARCH_CONTEXT_SIZE` | `medium` | 検索コンテキストのサイズ（`low` / `medium` / `high`）。`high` にするとより多くの情報を取得するがコストが増加 |
| `REASONING_EFFORT` | `medium` | 推論の深さ（`low` / `medium` / `high`）。`high` にするとより深い分析を行うがコストが増加 |

```bash
# 例: 推論の深さを high に変更する場合
export REASONING_EFFORT="high"
```

### 動作確認

Claude Code セッション内で o3-search-mcp のツール `web_search` が利用可能か確認:

```text
# セッション内で web_search を使って推論付き Web 検索を実行する例
web_search で React Server Components のパフォーマンス特性を調査して
```

### 使い分け

| 用途 | 手段 |
| --- | --- |
| 軽い検索（エラー解決、API仕様確認、単発の事実確認） | Brave Search MCP |
| 推論付き検索（技術比較、根本原因分析、設計判断） | o3-search-mcp |
| 大規模調査（網羅的スキャン、複数観点の調査） | gemini-analyzer |

詳細は `.claude/rules/web-delegation.md` を参照してください。

### 無効化する場合

`.mcp.json` から `o3-search` エントリを削除してください（他の MCP サーバー設定はそのまま残します）。

### 注意事項

- OpenAI API の利用料金が発生します（約 $0.05〜$0.15/回、設定により変動）
- **Tier 4 以上**の API アクセスが必要です。Tier が不足している場合はエラーが返されます
- `OPENAI_API_KEY` 環境変数が未設定の場合、MCP サーバーの起動に失敗します
- `npx` による初回起動時にパッケージのダウンロードが発生します
- Node.js（v18 以上）が必要です

## Semgrep MCP サーバー（オプション）

テンプレートには [Semgrep MCP](https://github.com/semgrep/semgrep) サーバーの設定が `.mcp.json` に含まれています。Semgrep は 5,000 以上のルールでセキュリティ脆弱性やバグパターンを検出する静的解析ツールで、MCP 経由で Claude Code から直接スキャンを実行できます。

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `.mcp.json` | Semgrep MCP サーバーの設定（`semgrep` エントリ） |

### 前提条件

テンプレートのデフォルト設定（`.mcp.json`）は `uvx` 経由で `semgrep-mcp` を起動するため、`uv` のインストールが必要です。インストール方法は公式手順を参照してください:

https://docs.astral.sh/uv/getting-started/installation/

```bash
# 例1: Homebrew でインストール（macOS）
brew install uv

# 例2: インストールスクリプトをダウンロードして内容を確認してから実行（macOS / Linux）
curl -LsSf https://astral.sh/uv/install.sh -o install-uv.sh
# 内容を確認してから実行
sh install-uv.sh

# インストール確認（.mcp.json と同じ引数で確認）
uvx --from semgrep-mcp==0.1.0 semgrep-mcp --help
```

`uv` を使わずに Semgrep MCP をローカルインストールで起動する場合は、`.mcp.json` の `semgrep` エントリを以下のように変更してください:

```json
"semgrep": {
  "command": "semgrep-mcp",
  "args": []
}
```

この場合、`pip install semgrep-mcp` で事前にインストールが必要です。

### 動作確認

Claude Code セッション内で Semgrep MCP のツールが利用可能か確認:

```text
# Claude Code セッション内で Semgrep のツール一覧を確認
Semgrep のツールを使ってこのプロジェクトをスキャンして
```

ターミナルで MCP サーバーの起動を直接確認する場合（`.mcp.json` と同じ引数で確認）:

```bash
uvx --from semgrep-mcp==0.1.0 semgrep-mcp --help
```

### 無効化する場合

`.mcp.json` から `semgrep` エントリを削除してください（他の MCP サーバー設定はそのまま残します）。

### 推奨実行タイミング

- **PR 作成前**: コミット前にセキュリティスキャンを実行し、脆弱性を早期に検出
- **依存関係更新後**: `package.json` や `requirements.txt` 等の更新後にスキャンを実行
- **リリース前**: リリースブランチのカットやタグ付け前に最終スキャンを実施

### 注意事項

- Semgrep はローカル実行のため、外部にコードを送信しません
- 偽陽性が発生する場合がありますが、ブロッキングではなく情報提供として活用してください
- `uvx` は Python パッケージの一時的な実行環境を提供します（`uv` のインストールが必要）

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

## リアクティブフック: CwdChanged / FileChanged（オプション）

Claude Code v2.1.83 以降で利用可能な `CwdChanged` / `FileChanged` フックイベントを活用して、ディレクトリ移動やファイル変更に応じた環境の自動リロードを設定できます。モノレポ等でサービスごとに環境設定が異なる場合の事故防止に有効です。

### 背景

- `CwdChanged`: Claude がディレクトリを移動した際に発火。direnv 連携等で環境変数を自動リロードできる
- `FileChanged`: 監視対象ファイルの変更を検知して発火。`.envrc` や `.env` の変更時に環境を自動更新できる
- JSON ではコメントアウトができないため、設定例はこのドキュメントで提供する（テンプレートの `settings.json` には含まない）

参考: [Claude Code Hooks ドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks)

### CwdChanged の設定例（direnv 連携）

Claude がディレクトリを移動するたびに `direnv export bash` を実行し、環境変数を自動リロードする例:

```json
{
  "hooks": {
    "CwdChanged": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash | grep '^export ' | sed 's/^export //'",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

> **注意:** `direnv allow` はフック内で自動実行しないでください。事前に `direnv allow .` を手動で実行し、信頼するディレクトリを明示的に許可してください。フック内で自動実行すると、悪意ある `.envrc` が紛れた場合に任意コマンド実行に直結します。

### FileChanged の設定例（.envrc / .env 変更時のリロード）

`.envrc` や `.env` ファイルが変更された際に環境をリロードする例:

```json
{
  "hooks": {
    "FileChanged": [
      {
        "matcher": "**/.envrc",
        "hooks": [
          {
            "type": "command",
            "command": "direnv export bash | grep '^export ' | sed 's/^export //'",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "**/.env",
        "hooks": [
          {
            "type": "command",
            "command": "set -a && . .env && set +a && sh -c 'for key in NODE_ENV PORT; do eval \"value=\\${$key}\"; [ -n \"$value\" ] && printf \"%s=%s\\n\" \"$key\" \"$value\"; done'",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### 有効化手順

1. 上記の設定例から必要なものを選択
2. プロジェクト固有の追加設定として `.claude/settings.local.json` の `hooks` セクションに追記（テンプレート管理の `.claude/settings.json` や既存の `SessionEnd` 等を上書きしないよう注意）
3. direnv を使用する場合は、事前に `direnv` をインストールし、シェルに hook を設定しておく
4. direnv を使用する場合は、対象ディレクトリで `direnv allow .` を手動で実行し、信頼するディレクトリを事前に許可しておく
5. プロジェクト固有の `.envrc` / `.env` が存在することを確認
6. `.env` 変更時のフックで出力するキー名（`NODE_ENV PORT` 等）をプロジェクトで使用する環境変数に合わせて変更する

### 注意事項

- これらのフックは downstream プロジェクトの環境に依存するため、テンプレートではオプション扱い（`settings.json` には含めない）
- direnv を使用しない環境では `CwdChanged` フックは不要
- `.env` ファイルの直接 source（`. .env`）はファイル内の任意のシェルコマンドが実行されるリスクがある。信頼できる `.env` ファイルでのみ使用し、不特定のファイルを自動 source しないこと。より安全な方法として、`grep` で `KEY=VALUE` 行のみを抽出するパーサーの使用を検討すること
- `.env` の直接 source は簡易的な方法であり、複雑な環境設定には direnv の使用を推奨
- `env` コマンドで全環境変数を出力すると機密情報がログに残る可能性があるため、必要なキーのみを明示的に出力すること
- フック活用のベストプラクティスは `.claude/rules/reactive-hooks.md` を参照

## PostToolUse 品質ゲートフック（オプション）

PostToolUse フックを使い、コミット時（実行直後）の lint やファイル編集後の型チェックを自動実行できます。エラーがあれば Claude にフィードバックされ、自動修正が促されます。

### Phase 1: コミット時 lint 自動実行

`Bash` ツールで `git commit` 実行後に `pnpm lint` を自動実行します:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "if printf '%s' \"$CLAUDE_TOOL_INPUT\" | grep -q 'git commit'; then pnpm lint --quiet 2>&1 || true; fi; true",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Phase 2: TypeScript 型チェック

`Edit` / `Write` ツールで `.ts` / `.tsx` ファイル編集後に `tsc --noEmit` を自動実行します:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "if printf '%s' \"$CLAUDE_TOOL_INPUT\" | grep -qE '\\.(ts|tsx)'; then pnpm tsc --noEmit 2>&1 | head -20 || true; fi; true",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### 導入手順

1. `.claude/settings.local.json`（プロジェクトローカル設定）の `hooks.PostToolUse` セクションに上記の設定を追記する（テンプレート管理の `.claude/settings.json` を上書きしないよう注意）
2. まず Phase 1（lint）のみ導入し、動作を確認する
3. Phase 2（型チェック）はプロジェクトに TypeScript がある場合のみ追加する
4. タイムアウト値（デフォルト 30秒）はプロジェクトの lint/型チェック実行時間に応じて調整する

### カスタマイズ

- パッケージマネージャが `pnpm` 以外の場合は `npm` / `yarn` に置き換える
- lint コマンドが `eslint` 直接実行の場合は `pnpm lint` を `npx eslint .` 等に変更する
- 運用ガイドラインの詳細は `.claude/rules/quality-gate-hooks.md` を参照

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

## 仕様駆動開発（Spec-Driven Development）

テンプレートには仕様駆動開発のためのディレクトリとテンプレートが含まれています。

### 概要

大きな機能をいきなり Claude Code に実装させると、ファイル配置やライブラリ選択がプロジェクトの慣習から外れることがあります。事前に Markdown の仕様書（要件、技術的制約、受け入れ基準）を `docs/specs/` に作成し、それに基づいて実装させることで品質が大幅に向上します。

参考: [規範駆動開発](https://note.com/tatsuruokada/n/n72b7c8923b62)

### 含まれるファイル

| ファイル | 説明 |
| --- | --- |
| `docs/specs/_template.md` | 仕様書テンプレート（概要、要件、技術的制約、受け入れ基準、ファイル配置、使用ライブラリ、テスト要件） |
| `.claude/CLAUDE.md` | `docs/specs/` への参照パターンを記載済み |

### Issue と docs/specs/ の併用ワークフロー

Issue（議論・タスク管理）と `docs/specs/`（確定仕様の永続化）を併用します:

1. **Issue で議論・承認**: 要件の議論、タスク分解、優先度の決定を Issue で行う（従来の Issue 駆動開発そのまま）
2. **仕様書に書き出し**: 確定した仕様を `docs/specs/` に Markdown で書き出す。テンプレート（`docs/specs/_template.md`）をコピーして使用
3. **Claude Code が自動参照して実装**: `docs/specs/jwt-auth.md の仕様通りに実装して` のように指示すると、Claude Code が仕様書を読み込んで実装する

この併用により、Issue の議論・進捗管理の利点と、Claude Code が仕様を自動読み込みできる `docs/specs/` の利点を両立します。

### 仕様書の作成手順

1. `docs/specs/_template.md` をコピーして新しいファイルを作成（例: `docs/specs/jwt-auth.md`）
2. 各セクション（概要、要件、技術的制約、受け入れ基準等）を記入
3. 関連する Issue 番号をリンク
4. コミットしてリポジトリに保存

### Claude Code への仕様書の渡し方

```text
# 仕様書を指定して実装を依頼
docs/specs/jwt-auth.md の仕様通りに実装して

# Issue と仕様書の両方を参照
Issue #15 の要件を docs/specs/jwt-auth.md の仕様に基づいて実装して

# 仕様書の作成自体を依頼
Issue #15 の内容を docs/specs/_template.md のフォーマットで仕様書にまとめて
```

### カスタマイズ

- **テンプレートのセクション変更**: `docs/specs/_template.md` のセクションをプロジェクトに合わせて追加・削除
- **CLAUDE.md の参照パターン**: `.claude/CLAUDE.md` の「仕様書」セクションをプロジェクトの運用に合わせて編集
- **テンプレート同期**: `docs/specs/` は既に `.templatesyncignore` で除外済み。downstream で同期したい場合は、`.templatesyncignore` から `docs/specs/` の行を削除

## `.claude/skills/` ディレクトリ

`.claude/skills/` にはプロジェクト固有のスキルを配置します（例: Supabaseマイグレーション用スキル等）。

### テンプレート同梱スキル

テンプレートには [obra/superpowers](https://github.com/obra/superpowers) にインスパイアされた以下のスキルが含まれています。各スキルは `.claude/skills/{スキル名}/SKILL.md` に配置されており、Claude Code が自動的に認識します。

| スキル | 説明 | トリガー |
| --- | --- | --- |
| `test-driven-development` | RED-GREEN-REFACTOR サイクルによる TDD ワークフロー | 機能実装・バグ修正の開始時 |
| `requesting-code-review` | サブエージェントによるコードレビュー（Critical/Important/Minor 三段階評価） | 主要機能完了時・PR 作成前 |
| `verification-before-completion` | 完了宣言前の実行証拠確認（推測での完了宣言を防止） | 「完了しました」と宣言する前 |
| `differential-review` | PR・コミット差分のセキュリティ特化レビュー（認証・暗号・外部呼び出しのリスク優先分析） | セキュリティ関連コード変更時 |
| `static-analysis` | Semgrep・CodeQL を活用した静的セキュリティ解析・SARIF トリアージ | セキュリティ監査・依存関係更新後 |
| `second-opinion` | OpenAI Codex CLI・Google Gemini CLI によるマルチ LLM コードレビュー | セキュリティクリティカルな変更時 |

#### 既存フローとの関係

- **test-driven-development** → `.claude/rules/git-conventions.md` のセルフレビュー「テスト十分性」項目の根拠となる
- **requesting-code-review** → セルフレビュー（毎コミット）と `/review-respond`（PR 後の Copilot レビュー対応）の間を埋める、PR 作成前のサブエージェントレビュー
- **verification-before-completion** → セルフレビューチェックリストの各項目に対する検証品質を担保する補完スキル
- **differential-review** → Trail of Bits のセキュリティレビュー手法を参考にした、セキュリティ特化の差分レビュー。`requesting-code-review` が一般的な品質レビューを担うのに対し、認証・暗号・外部呼び出し等のセキュリティ観点に特化
- **static-analysis** → Semgrep/CodeQL を活用した静的解析。外部ツール（Semgrep CLI 等）が必要。前提条件は下記「セキュリティスキルの前提条件」参照
- **second-opinion** → 外部 LLM（Codex CLI/Gemini CLI）による多角的レビュー。外部ツールが必要。機密コードには使用注意

#### セキュリティスキルの前提条件

セキュリティスキル（`differential-review`, `static-analysis`, `second-opinion`）は Trail of Bits のセキュリティレビュー手法を参考にしています。各スキルの前提条件は以下の通りです。

| スキル | 必要な外部ツール | インストール方法 |
| --- | --- | --- |
| `differential-review` | なし（`git` のみ） | — |
| `static-analysis` | Semgrep CLI（推奨）、CodeQL CLI（任意）、jq（推奨） | `pip install semgrep` / `brew install semgrep` / `brew install jq` / CodeQL CLI: [GitHub Releases](https://github.com/github/codeql-cli-binaries/releases) |
| `second-opinion` | OpenAI Codex CLI または Google Gemini CLI（少なくとも1つ） | `npm i -g @openai/codex` / `npm i -g @google/gemini-cli` |

**`differential-review`** は外部ツール不要で即座に利用できます。`static-analysis` と `second-opinion` は外部ツールのインストールが必要なため、段階的に導入することを推奨します。

**注意事項:**
- `second-opinion` は外部 LLM にコードを送信するため、機密性の高いコードでは使用を控えてください
- `static-analysis` で Semgrep を使用する場合は `--metrics=off` を指定してテレメトリ送信を無効化してください
- 各スキルの詳細なワークフローは `.claude/skills/{スキル名}/SKILL.md` を参照してください

#### カスタマイズ

- 不要なスキルはディレクトリごと削除してください
- プロジェクト固有のスキルを追加する場合は、同じ形式（`.claude/skills/{スキル名}/SKILL.md`）で配置してください

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

## コスト可視化（ステータスライン）

Claude Code のカスタムステータスラインを使って、セッションコストやコンテキスト使用率をリアルタイムに確認できます。

### 概要

デフォルトではセッションのトークン消費量やコンテキストウィンドウの残量が把握しづらいため、`/statusline` コマンドでターミナル下部に情報を常時表示することを推奨します。

### `/statusline` コマンドの使い方

`/statusline` は自然言語で表示内容を設定できます:

```text
/statusline show me model, session cost, and context usage percentage
```

### 推奨表示項目

| 項目 | 説明 |
| --- | --- |
| モデル名 | 使用中の Claude モデル（Opus / Sonnet / Haiku） |
| セッションコスト | 現在のセッションで消費したトークンのコスト |
| コンテキスト使用率 | コンテキストウィンドウの使用率（圧縮タイミングの判断に有用） |
| Git ブランチ | 現在作業中のブランチ名 |

### コミュニティツール

ステータスラインの表示をさらにカスタマイズできるコミュニティツールがあります:

- **[ccstatusline](https://github.com/search?q=ccstatusline&type=repositories)** — ステータスラインのカスタマイズツール
- **[claude_monitor_statusline](https://github.com/search?q=claude_monitor_statusline&type=repositories)** — セッション監視向けのステータスライン拡張

### 注意事項

- ステータスラインは個人の好みに依存するため、テンプレートの `.claude/settings.json` には含めていません
- 各ユーザーが `/statusline` コマンドで個別に設定してください
- 設定はセッション単位で保持されます

参考: [Claude Code コスト可視化](https://note.com/tatsuruokada/n/n72b7c8923b62)

## 書き換え手順

1. テンプレートからリポジトリを作成
2. 上記一覧に従い、プレースホルダ（`{project}-`, `{github_username}` 等）を実際の値に置換
3. `.claude/CLAUDE.md` にプロジェクト概要・技術スタックを記載
4. `.claude/rules/project-structure.md` にプロジェクト固有のルールを記載
5. 必要に応じて `.claude/skills/` にプロジェクト固有のスキルを追加
6. テンプレート同期を有効化（[docs/template-sync.md](docs/template-sync.md) 参照）:
   - `gh secret set TEMPLATE_SYNC_TOKEN` でテンプレート同期用PATを設定（必要な権限: Contents R/W, Pull requests R/W, Issues R/W, Workflows R/W）。権限が不足すると `.github/workflows/template-sync.yml` 自体の同期時にpushが拒否される等の失敗が発生するため、詳細は [docs/template-sync.md](docs/template-sync.md#1-personal-access-token-pat-の作成) を参照
   - `.templatesyncignore` にプロジェクト固有ファイルを追加（例: `.claude/CLAUDE.md`, `.claude/settings.json`）。`.claudeignore` をカスタマイズする場合はダウンストリーム側の `.templatesyncignore` にも `.claudeignore` を追加すること（テンプレート側の `.templatesyncignore` は同期されないため）。詳細は [docs/template-sync.md](docs/template-sync.md) の該当セクションを参照
   - `gh workflow run template-sync.yml` で動作確認
7. この `SETUP.md` は書き換え完了後に削除してOK
