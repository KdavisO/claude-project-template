---
description: リリースを実行します（バージョンバンプ、CHANGELOG更新、git tag、GitHub Release作成）
---

リリースを実行してください。

引数: `$ARGUMENTS`

## 引数の解析

- 引数なし → 自動でバージョンバンプの種別を判定
- `patch` / `minor` / `major` → 指定された種別でバンプ（自動判定をスキップ）
- `--dry-run` → 実際の変更を行わず、実行内容のプレビューのみ表示

## 手順

### 1. 事前確認

1. 現在のブランチが `main` であることを確認する（main以外ではリリース禁止）
2. ワーキングツリーがクリーンであることを確認する（未コミットの変更がある場合はエラー）
3. `git pull --ff-only origin main` でリモートと同期する

### 2. 現在のバージョンを取得

1. 最新の git tag を取得する:
   ```bash
   git describe --tags --abbrev=0 2>/dev/null
   ```
2. タグが存在しない場合は `v0.0.0` を初期バージョンとする
3. タグから `v` プレフィックスを除去してバージョン番号を取得（例: `v1.2.3` → `1.2.3`）

### 3. バージョンバンプの種別を判定

引数で種別が指定されている場合はそれを使用する。指定がない場合は自動判定:

1. 前回タグからのコミットメッセージを取得する:
   ```bash
   git log {前回タグ}..HEAD --pretty=format:"%s"
   ```
   （タグがない場合は全コミットを対象にする）

2. コミットメッセージのプレフィックスに基づいて判定:
   - `BREAKING CHANGE` を含む or コミットメッセージに `!:` を含む → **major**
   - `feat:` が1つ以上ある → **minor**
   - それ以外（`fix:`, `refactor:`, `docs:`, `chore:` 等のみ） → **patch**

3. 新しいバージョン番号を計算する（例: `1.2.3` + minor → `1.3.0`）

### 4. ドライランチェック

`--dry-run` が指定されている場合、以下を表示して終了:

```
🔍 ドライラン結果:
- 現在のバージョン: v{current}
- バンプ種別: {patch|minor|major}
- 新しいバージョン: v{new}
- 対象コミット数: {N}
- CHANGELOG に追加されるエントリ:
  {CHANGELOGプレビュー}
```

### 5. CHANGELOG.md を更新

1. リポジトリルートに `CHANGELOG.md` が存在しない場合は新規作成する
2. 前回タグからのコミットを以下のカテゴリに分類する:
   - `feat:` → **Features**
   - `fix:` → **Bug Fixes**
   - `refactor:` → **Refactoring**
   - `ui:` → **UI/UX**
   - `docs:` → **Documentation**
   - `chore:`, `test:` その他 → **Other Changes**
3. 以下のフォーマットで `CHANGELOG.md` の先頭（`# Changelog` ヘッダの直後）に追記する:

```markdown
## [v{version}](https://github.com/{owner}/{repo}/releases/tag/v{version}) ({YYYY-MM-DD})

### Features
- コミットメッセージ（プレフィックス除去済み）

### Bug Fixes
- コミットメッセージ

...（空のカテゴリは省略）
```

### 6. コミット・タグ作成

1. CHANGELOG.md の変更をコミットする:
   ```bash
   git add CHANGELOG.md
   git commit -m "chore: release v{version}"
   ```
2. アノテーション付き git tag を作成する:
   ```bash
   git tag -a v{version} -m "Release v{version}"
   ```

### 7. push

1. コミットとタグをリモートに push する:
   ```bash
   git push origin main --follow-tags
   ```

### 8. GitHub Release を作成

1. `gh release create` でリリースを作成する:
   ```bash
   gh release create v{version} --title "v{version}" --generate-notes
   ```
   - `--generate-notes` により `.github/release.yml` の設定に基づいてリリースノートが自動生成される（必要に応じて `--notes-start-tag` で開始タグを指定する）
   - GitHub が自動生成するリリースノートが不十分な場合（タグ間のPRが取得できない等）は、CHANGELOG.md の該当バージョンのエントリをリリースノートとして使用する:
     ```bash
     gh release create v{version} --title "v{version}" --notes "{CHANGELOGの該当エントリ}"
     ```

### 9. 完了メッセージ

```
✅ リリース完了:
- バージョン: v{version}
- タグ: v{version}
- CHANGELOG: 更新済み
- GitHub Release: {リリースURL}
```
