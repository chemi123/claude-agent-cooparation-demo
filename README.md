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
