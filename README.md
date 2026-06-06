# Claude Agent Cooperation Demo

Claude Code + tmux を使ったマルチエージェント協調パイプラインの実験的実装。

複数の Claude Code インスタンスがそれぞれ独立したロールを持ち、tmux のメッセージパッシングとファイルシステムを介して協調動作する構造を検証する。

## アーキテクチャ

```
orchestrator
    │
    ├─ writer     ← サブテーマの記事を執筆
    │     │
    ├─ reviewer   ← 論理整合性・事実確認・必要に応じてウェブ検索
    │     │
    └─ editor     ← 全サブテーマを統合してサマリーを生成
```

各エージェントは専用ディレクトリ内の `CLAUDE.md` に従って動作する。

## 通信プロトコル

エージェント間の通信は tmux の `send-keys` によるメッセージパッシング。

```
writer  → "writer完了: shared/<テーマ>/<サブテーマ>.md"
reviewer → "reviewer完了: shared/<テーマ>/<サブテーマ>_reviewed.md (修正あり|修正なし)"
editor  → "editor完了: shared/<テーマ>/summary.md"
```

ポーリングは不要。各エージェントからのメッセージが届いたら即座に次のエージェントへルーティングする。

## ファイル構造

```
shared/
  <テーマ名>/
    <サブテーマ名>.md           # writer が生成
    <サブテーマ名>_reviewed.md  # reviewer が生成
    summary.md                  # editor が生成
```

テーマ名ディレクトリが実行単位となり、複数テーマの成果物が混在しない。

## 起動方法

```bash
./start.sh
```

新しい tmux セッション `agents` が作成され、4ペインで各エージェントが起動する。

```
┌─────────────────┬─────────────────┐
│                 │    writer       │
│  orchestrator   ├─────────────────┤
│                 │    reviewer     │
│                 ├─────────────────┤
│                 │    editor       │
└─────────────────┴─────────────────┘
```

あとは orchestrator ペインで CLAUDE.md の手順に従って指示を出すだけ。

## 設計の要点

- **CLAUDE.md がそのまま仕様書** — 各エージェントの指示と設計が同じファイルに収まる
- **疎結合** — エージェント同士は直接通信せず、orchestrator を中継点にする
- **run isolation** — テーマ名ディレクトリにより実行ごとの成果物が分離される
- **拡張容易性** — ロールの追加・差し替えが CLAUDE.md の追加だけで済む

---

## Claude Agent Teams との比較

Claude Code には [Agent Teams](https://code.claude.com/docs/ja/agent-teams) という公式のマルチエージェント機能（実験的）が存在する。
本リポジトリの構成はそれを自前で実装したものに相当する。

### 自前設計にする理由

- **動作が完全に可視化されている** — tmux + CLAUDE.md で何が起きているか全て読める
- **デバッグしやすい** — 問題が起きたとき原因が特定できる
- **experimental ではない** — 仕様変更・廃止のリスクがない
- **設計の理解が深まる** — ブラックボックスを使う前に内部構造を把握できる

### Agent Teams に移行するなら

`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` を有効にした上で、以下の変換で対応できる。

**1. エージェント定義を subagent として配置する**

```
.claude/agents/
  writer.md    ← writer/CLAUDE.md の役割定義部分
  reviewer.md  ← reviewer/CLAUDE.md の役割定義部分
  editor.md    ← editor/CLAUDE.md の役割定義部分
```

**2. tmux 通知を削除する**

各エージェントの完了通知（`tmux send-keys ...`）は不要になる。
Agent Teams のメッセージング機能が自動で配信する。

**3. orchestrator の手動ルーティングを自然言語に置き換える**

```diff
- tmux send-keys -t agents:0.x ...
- writer完了を受け取ったら reviewer へ転送...
+ writer/reviewer/editor チームを作り、
+ writer→reviewer→editor の順でパイプライン処理せよ
```

### 設計の本質は変わらない

「役割の定義（CLAUDE.md）」「ファイルベースのハンドオフ（shared/）」「パイプラインの順序」は
自前実装でも Agent Teams でも同じ。変わるのは「配管部分」だけ。
Agent Teams の仕様が変わっても、設計の考え方はそのまま適用できる。
