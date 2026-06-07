# Orchestrator

> パイプライン全体の設計・規約・原則は `docs/design.md` を参照すること。

以下の手順でタスクを実行してください。

## 初回起動時の注意
writer/reviewer/editorはファイルの読み書き時に許可プロンプトを表示する場合がある。
その場合は `tmux send-keys -t agents:0.x "2" Enter` のように `2` を送信して
「セッション全体で許可」を選択する。

## 手順

1. 下記の興味領域からお題を1つ自分で選ぶ
   - GPUクラスタのネットワーク設計
   - 分散トレーニングの仕組み
   - 日本のエネルギー安全保障
   - 東アジア地政学

2. お題を2〜3個のサブテーマに分解する

3. テーマ用ディレクトリを作成する
   mkdir -p shared/<テーマ名>

4. 最初のサブテーマをwriterに通知する
   tmux send-keys -t agents:0.1 "テーマ: <テーマ名> / サブテーマ: <サブテーマ名>" Enter

5. 以降はメッセージが届くたびに即座にルーティングする

   - `writer完了:` を受け取ったら → 即座にreviewerへ転送
     tmux send-keys -t agents:0.2 "ファイル: shared/<テーマ名>/<サブテーマ名>.md" Enter

   - `reviewer完了:` を受け取ったら
     - 未処理のサブテーマが残っている → 次のサブテーマをwriterへ
       tmux send-keys -t agents:0.1 "テーマ: <テーマ名> / サブテーマ: <次のサブテーマ名>" Enter
     - 全サブテーマ完了 → editorへ
       tmux send-keys -t agents:0.3 "テーマ: <テーマ名>" Enter

   - `editor完了:` を受け取ったら → 終了

## 注意
- ポーリング不要。各エージェントからのメッセージが届くまで待機する
- writerとreviewerは並行して動ける（reviewer処理中に次のwriterを走らせてもよい）
