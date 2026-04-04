---
description: 並列実行可能なIssueセットを提案します。
---

オープンIssueから並列実行可能なセットを提案してください。

引数: `$ARGUMENTS`

引数の解析ルール:

- 引数なし → デフォルト設定で実行
- 数字のみ（例: `2`）→ 並列数を指定
- `priority:xxx`（例: `priority:medium`）→ 指定優先度以上のみ対象
- `exclude:N[,N...]`（例: `exclude:245`, `exclude:245,250`）→ 指定Issue番号を除外（単数・複数どちらも可）
- 複数指定可（例: `3 priority:medium exclude:245`）
- `exclude:` の値はカンマ区切りでパースし、空要素は無視し、重複するIssue番号は除外時に一意になるよう正規化する前提とする

デフォルト値:

- 並列数: 3
- 優先度フィルタ: なし（全て対象）
- 除外Issue: なし

## 手順

### 1. オープンIssueの取得

```
gh issue list --state open --limit 100 --json number,title,labels,assignees
```

### 2. 領域マップの参照

`docs/issue-groups.md` が存在する場合は読み込み、以下の情報を把握する:

- 各Issueが属するグループと変更領域
- Issue間の依存関係
- 競合リスクが高いファイル

`docs/issue-groups.md` が存在しない場合は、この手順をスキップする。手順4の並列実行可能セット選定では、各Issueの変更対象ファイルを推測して独立性を判断する。

### 3. フィルタリング

以下の条件でIssueを除外する:

- 引数で `exclude:` に指定されたIssue
- 既にアサインされているIssue（他の開発者が作業中の可能性）
- 既にPRが存在するIssue（PR本文に `Closes #<issue番号>` / `Fixes #<issue番号>` / `Resolves #<issue番号>` が含まれるかを、`gh pr list --search "Closes #{issue番号} OR Fixes #{issue番号} OR Resolves #{issue番号}"` で確認して除外）
- `research` ラベルが付いたIssue（調査モード対象のため、並列実装には適さない）
- `priority:` フィルタが指定されている場合、該当優先度未満のIssue
  - 優先度の順序: `high` > `medium` > `low`
  - 例: `priority:medium` → `low` を除外

### 4. 並列実行可能セットの選定

以下の基準で並列実行可能なIssueセットを選定する:

1. **変更領域の独立性**: 変更対象ファイルが重複しないこと
2. **依存関係がないこと**: 片方の完了が他方の前提条件でないこと
3. **DBマイグレーション競合なし**: 同時にマイグレーションを追加しないこと（1セット内で最大1件まで）
4. **スコープのバランス**: 大きなIssueばかりにならないよう調整

スコープの判定基準:

- **小**: 1ファイル変更、テスト追加のみ、ドキュメント更新
- **中**: 2〜5ファイル変更、新規コンポーネント追加、API追加
- **大**: 6ファイル以上変更、DBマイグレーション含む、複数領域にまたがる

### 5. 提案の出力

以下のフォーマットで出力する:

```
## 並列実行提案

### 推奨セット 1（最推奨）

| # | Issue | 概要 | 領域 | スコープ |
|---|-------|------|------|----------|
| 1 | #XXX  | ...  | ...  | 小/中/大 |
| 2 | #YYY  | ...  | ...  | 小/中/大 |
| 3 | #ZZZ  | ...  | ...  | 小/中/大 |

**独立性の根拠**: （変更領域が重複しない理由を記載）

**開始コマンド**:
/issue-start XXX --parallel
/issue-start YYY --parallel
/issue-start ZZZ --parallel

---

### 推奨セット 2（代替案）

（同様のフォーマット）
```

- 最低2セット、可能であれば3セット提案する
- 各セットに独立性の根拠を必ず記載する
- `docs/issue-groups.md` に既存の推奨パターンがある場合は優先的に参照する
- セット内のIssueが `docs/issue-groups.md` に記載されていない場合は、変更対象ファイルを推測して独立性を判断する

### 6. 実行確認と開始

提案を表示した後、ユーザーに確認を求める:

```
開始するセットを選択してください（例: 1）。`none` でスキップ。
```

- ユーザーがセット番号を指定した場合、選択されたセットのIssueを並列実行する
- `none` の場合は提案表示のみで終了する

#### Agent Teams + worktree 方式（デフォルト）

環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が `"1"` に設定されている場合、Agent Teams + worktree のハイブリッド方式で並列実行を開始する（`.claude/settings.json` または `.claude/settings.local.json` の `env` セクションで設定）。

> `/patrol` や `/review-respond` と異なり `--team` フラグは不要。並列実行の開始がこのコマンドの主目的であるため、環境変数の値が `"1"` かどうかのみで判定する。

**`{project}` の導出方法**: メインリポジトリのディレクトリ名を使用する（`basename "$(dirname "$(git rev-parse --git-common-dir --path-format=absolute)")"`）。worktree 配下でも常にメインリポジトリ名が返るため、`/flow-status` のステータスファイル命名と一致する。

**`{ownerRepo}` の導出方法**: `gh repo view --json owner,name -q '.owner.login + "-" + .name'` で取得する。

**手順:**

1. 選択されたセット内の各Issueの情報を事前取得する:
   - `gh issue view {issue番号} --json title,body,labels` で各Issueの詳細を取得
   - Issueのラベルに基づきブランチ種別 `{type}` を決定する（`issue-start.md` の共通手順3と同じルール）
2. Agent Teams で `parallel-issues` という名前のチームを作成する
3. 各Issueに対してチームメイトを作成する:
   - `name`: `issue-{issue番号}`（例: `issue-123`）
   - `team_name`: `parallel-issues`
   - `subagent_type`: `general-purpose`（ファイル編集・Bash実行が必要なため）
   - 手順1で取得したIssue内容をチームメイトへの指示に埋め込む（各チームメイトが個別に `gh issue view` を実行しなくてよいようにする）
4. 各チームメイトの進捗を監視し、全員の完了を待つ
5. **ポーリング引き継ぎ**（全チームメイト完了後、シャットダウン前に実施）:
   - 各チームメイトの完了報告からPR番号・ブランチ名・worktreeの絶対パスを収集する（cronタスクIDファイルはPR番号から固定パス `/tmp/{project}-review-{ownerRepo}-cron-{PR番号}` で特定できる）
   - 各PRについて以下を順次実行する:
     1. cronタスクIDファイル（`/tmp/{project}-review-{ownerRepo}-cron-{PR番号}`）を読み取り、チームメイトのcronタスクIDを取得する
     2. 対象PRのworktreeパスを決定し、そのディレクトリに移動する。完了報告に含まれるworktreeの絶対パスを使って `cd {worktreeパス}` する。報告されたworktreeパスが欠落・不正・到達不能な場合のみ、`git worktree list` からブランチ名でworktreeパスを再特定して `cd` する。`/review-respond` がコード修正・コミット・プッシュを行う際にPRブランチで正しく動作するために必要。いずれの方法でもworktreeを特定できない場合は、そのPRの引き継ぎをスキップし警告を出力する
     3. worktreeディレクトリ内で、リードから新しいポーリングを開始する: `/loop 4m --skip-first /review-respond --auto --max-idle 3 {PR番号}`
     4. `/loop`（CronCreate）の戻り値から新しいcronタスクIDを取得し、cronタスクIDファイルを上書きする
     5. 新しいポーリングの作成とcronタスクIDファイル更新の成功を確認してから、手順1で取得した旧タスクIDで `CronDelete` を実行し、チームメイトのcronタスクを明示的に削除する
   - cronタスクIDファイルが存在しない場合（Copilotレビューリクエスト失敗等でポーリング未開始）はそのPRをスキップし、警告を出力する
   - 新しいポーリングの作成またはcronタスクID取得に失敗した場合は、旧cronタスクを削除せずそのPRの引き継ぎをスキップし、警告を出力する
   - 全PRのポーリング引き継ぎが完了してから、手順6のシャットダウンに進む
   - **注意（CWDとworktreeの関係）**: 引き継ぎ後のポーリングが発火する際のCWDはリードセッションのその時点のCWDとなる。PRが1件の場合はそのworktreeに留まればよい。**複数PRの場合は以下のいずれかの方法を採用すること**:
     - **推奨**: PRごとに別セッション（サブエージェント等）で `/loop` を作成し、各セッションのCWDを対象worktreeに固定する
     - **代替**: 各PRのworktreeパスをポーリングコマンドに組み込み、発火時に必ず正しいworktreeへ移動してから実行する
     - 上記のいずれも適用できない場合は、複数PRのポーリング引き継ぎを行わず手動運用とする
   - マージ完了後のworktreeクリーンアップは `/worktree-cleanup` で手動実行すること（ポーリング引き継ぎ後はリードのメインリポジトリコンテキストではなくworktreeコンテキストで動作するが、CWD変動により `/review-respond` のポストアクション手順10-Cによる自動worktree削除が確実に動作する保証はないため）
6. 各チームメイトに終了を指示してチームを解散する
7. 全チームメイトの結果を統合して完了サマリーを出力する:
   ```
   === 並列実行 完了サマリー ===
   | Issue | ブランチ | PR | 状態 |
   |-------|----------|-----|------|
   | #XXX  | feat/... | #NN | 完了 |
   | #YYY  | fix/...  | #MM | 完了 |
   ...
   ===========================
   ```

**チームメイトへの指示テンプレート:**

```
Issue #{issue番号}「{Issueタイトル}」を実装してください。

## Issue内容
{リードが事前取得したIssue内容}

## 作業手順
1. worktree を作成して移動:
   git fetch origin main
   git worktree add ../{project}-{type}-{issue番号} -b {type}/{issue番号}-{英語の短い説明} origin/main
   cd ../{project}-{type}-{issue番号}

2. ステータスファイルを作成（/flow-status による進捗確認用、原子的書き換え）:
   STATUS_FILE="/tmp/{project}-flow-{ownerRepo}-{issue番号}"
   STATUS_FILE_TMP="${STATUS_FILE}.tmp"
   printf '{"issue":{issue番号},"branch":"{type}/{issue番号}-{英語の短い説明}","pr":null,"phase":"implementing","worktree":"{worktreeの絶対パス}","updated_at":"%s","error":null}' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "${STATUS_FILE_TMP}" && mv "${STATUS_FILE_TMP}" "${STATUS_FILE}"

3. 依存関係のインストール:
   if [ -f package.json ]; then
     pnpm install
   fi

4. Issue要件に基づいて実装

5. セルフレビュー・コミット（git-conventions.md に従う）

6. PR作成・自動レビューフロー:
   - Copilotレビューリクエストの並列実行によるレースコンディションを回避するため、PR作成前にランダムディレイ（3〜8秒）を挿入する:
     ```bash
     sleep $((RANDOM % 6 + 3))
     ```
   - `/issue-pr --auto {issue番号}` を実行してPRを作成する（Copilotレビューリクエスト・レビュー対応ポーリングの「開始」までを含む）
   - `/issue-pr --auto` の成功後、ステータスファイルを更新（原子的書き換え）: 手順2で使用した STATUS_FILE / STATUS_FILE_TMP を用い、`.tmp` に書き出してから `mv` で置き換える手順で、phase を "pr-created" に、pr フィールドにPR番号を設定し、updated_at を現在時刻に更新する
   - Copilotレビューリクエストが成功した場合、`/issue-pr --auto` が自動で `/loop ... /review-respond --auto --max-idle 3` によるレビュー対応ポーリングを開始する。このポーリングはcronでバックグラウンド実行され、`/issue-pr --auto` 自体はポーリング完了まで同期的には待機しない
   - ポーリング開始を確認したら、ステータスファイルを更新: phase を "polling" に設定し、updated_at を現在時刻に更新する（ここではポーリング完了を待たずに次の手順へ進む）
   - PRマージは `/review-respond --auto --max-idle 3` のポストアクション（手順10-A）で自動実行される。worktreeクリーンアップ（手順10-C）はポーリング実行時のCWDがworktree内である場合のみ自動実行される（リードへのポーリング引き継ぎ後はCWD変動により自動実行されない場合があるため、`/worktree-cleanup` での手動クリーンアップも想定すること）

7. 完了をリードに報告（ブランチ名、PR番号、worktreeの絶対パス、変更ファイル一覧を含める。cronタスクIDファイルはPR番号から固定パス `/tmp/{project}-review-{ownerRepo}-cron-{PR番号}` で特定できる前提とする）

8. ステータスファイルのクリーンアップ:
   - 正常終了時:
     - ステータスファイルを原子的書き換えで最終更新: phase を "completed" に、updated_at を現在時刻に設定
     - 最終更新後にステータスファイルを削除（`rm "${STATUS_FILE}"`）。`/flow-status` では completed フェーズは通常ファイル削除後に表示されない前提のため、成功時は削除して過去の実行が残り続けないようにする
   - エラーで中断した場合:
     - ステータスファイルが存在する場合は原子的書き換えで更新し、phase を "error" に、updated_at を現在時刻に設定し、可能であれば error フィールドに概要を記録する
     - エラー時はステータスファイルを削除しない（`/flow-status` で原因確認できるようにする）

## 注意事項
- 必ず worktree 内で作業すること（元のリポジトリを変更しない）
- ブランチ命名: {type}/{issue番号}-{英語の短い説明}
- コミットメッセージ: プレフィックス必須（feat:, fix: 等）、日本語可
- 他のチームメイトの担当領域のファイルを変更しないこと: {他チームメイトの担当領域を列挙}
- worktree が既に存在する場合はエラーメッセージをリードに報告すること
```

#### フォールバック（従来方式）

以下の場合は Agent Teams を使用せず、従来のコマンド出力のみを表示する:

- 環境変数 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` が `"1"` でない（未設定を含む）
- Agent Teams の作成に失敗した場合（エラーメッセージを表示し、コマンド一覧をフォールバックとして出力）

フォールバック時の出力:
```
以下のコマンドを各ターミナルで実行してください:
/issue-start XXX --parallel
/issue-start YYY --parallel
/issue-start ZZZ --parallel
```
