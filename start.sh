#!/bin/bash

# ディレクトリ構成確認
mkdir -p shared

# セッション作成
tmux new-session -d -s agents

# ペイン分割: 左にorchestrator、右にwriter/reviewer/editorを縦3分割
tmux split-window -h -t agents:0
tmux split-window -v -t agents:0.1
tmux split-window -v -t agents:0.2

# レイアウト調整: main-verticalでpane0を左に固定、右3ペインを均等化
tmux select-pane -t agents:0.0
tmux select-layout -t agents main-vertical
tmux resize-pane -t agents:0.0 -x 117

# ペインタイトル設定
tmux set-window-option -t agents pane-border-status top
tmux set-window-option -t agents pane-border-format "#{pane_title}"
tmux select-pane -t agents:0.0 -T "orchestrator"
tmux select-pane -t agents:0.1 -T "writer"
tmux select-pane -t agents:0.2 -T "reviewer"
tmux select-pane -t agents:0.3 -T "editor"

# 各ペインで起動
tmux send-keys -t agents:0.0 "claude" Enter
tmux send-keys -t agents:0.1 "cd writer && claude" Enter
tmux send-keys -t agents:0.2 "cd reviewer && claude" Enter
tmux send-keys -t agents:0.3 "cd editor && claude" Enter

# アタッチ
tmux attach -t agents
