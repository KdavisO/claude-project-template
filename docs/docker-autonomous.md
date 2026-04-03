# Docker 自律実行ガイド

Docker コンテナ内で Claude Code を `--dangerously-skip-permissions` フラグ付きで実行し、完全自律モードで動作させるためのガイド。

## なぜ Docker で実行するか

- **許可疲れの解消**: ファイル書き込み・シェルコマンド・テスト実行のたびに承認が不要になる
- **ホスト環境の安全性**: コンテナ内に隔離されるため、ホストマシンへの影響がない
- **再現性**: 同一の実行環境を誰でも再現できる
- **CI/CD 統合**: 自動パイプラインに組み込みやすい

## セットアップ

### 前提条件

- Docker および Docker Compose がインストール済み
- Anthropic API キーを取得済み

### 環境変数の設定

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
```

または `.env` ファイルに記載:

```
ANTHROPIC_API_KEY=sk-ant-...
```

> **注意**: `.env` ファイルは `.gitignore` に追加し、リポジトリにコミットしないこと。

## 使用方法

### 対話モード

```bash
docker compose run --rm claude
```

### プロンプト指定

```bash
docker compose run --rm claude "Issue #123 を実装してください"
```

### ファイル入力（`-p` オプション）

```bash
docker compose run --rm claude -p "$(cat prompt.txt)"
```

### パイプ入力

```bash
echo "テストを追加してください" | docker compose run --rm claude
```

## CI/CD での使用パターン

### GitHub Actions

```yaml
jobs:
  claude-code:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Claude Code
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          docker compose run --rm claude "全テストを実行し、失敗があれば修正してください"
```

### 夜間バッチ処理

```yaml
# .github/workflows/nightly-claude.yml
on:
  schedule:
    - cron: '0 0 * * *'  # 毎日 UTC 0:00

jobs:
  nightly:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Claude Code
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          docker compose run --rm claude "コードベースを分析し、改善提案をIssueとして起票してください"
```

## セキュリティ上の注意

- **API キーの管理**: 環境変数またはシークレット管理ツール経由で渡す。Dockerfile やイメージ内にハードコードしない
- **ネットワーク制限**: 必要に応じて `docker-compose.yml` で `network_mode: "none"` を設定し、外部通信を制限できる
- **ボリュームマウント**: マウント先はプロジェクトディレクトリに限定し、ホストのホームディレクトリ全体をマウントしない
- **イメージの更新**: Claude Code のバージョンアップに追従するため、定期的にイメージをリビルドする
- **コンテナ内の権限**: Dockerfile では非 root ユーザー（`claude`）で実行するよう設定済み

## カスタマイズ

### 追加ツールのインストール

プロジェクト固有のツールが必要な場合、Dockerfile を拡張する:

```dockerfile
# 例: Python 環境を追加
RUN apt-get update && apt-get install -y python3 python3-pip
```

### モデルの指定

```bash
docker compose run --rm claude --model claude-sonnet-4-6 "軽量タスクを実行"
```

### 最大ターン数の制限

```bash
docker compose run --rm claude --max-turns 10 "スコープを限定したタスク"
```
