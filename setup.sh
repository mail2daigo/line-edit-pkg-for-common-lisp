#!/bin/bash

# エラーが発生したら停止
set -e

# 定義
CONF_DIR="$HOME/.config/line-edit"
BUILD_UTILS="build-utils.lisp"

echo "Starting setup..."

# 1. ~/.config/line-edit の作成
# -p フラグを使うことで、親ディレクトリ (~/.config) がなくても再帰的に作成し、
# 既に存在する場合もエラーにならない。
if [ ! -d "$CONF_DIR" ]; then
    echo "creating directory: $CONF_DIR"
    mkdir -p "$CONF_DIR"
fi

# 2. 設定ファイルの配置

cp emacs*.* $CONF_DIR/
cp vi*.* $CONF_DIR/
cp WordMaster*.* $CONF_DIR/
cp cursor-info.lisp $CONF_DIR/
cp init-repl-prompt.lisp $CONF_DIR/
cp line-edit-init.lisp $CONF_DIR/
cp registered-message-file $CONF_DIR/
cp set-editor-mode.lisp $CONF_DIR/
cp syntax-info-list.lisp $CONF_DIR/
cp user-info-list.lisp $CONF_DIR/

# 3. build-utils.lisp の移動
if [ -f "$BUILD_UTILS" ]; then
    cp "$BUILD_UTILS" "$HOME/"
    echo "$BUILD_UTILS moved to $HOME/"
else
    echo "error: $BUILD_UTILS not found in current directory."
    exit 1
fi

echo "Setup completed successfully."
