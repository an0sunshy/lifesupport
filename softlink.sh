#!/bin/sh

NVIM_CONFIG_DIR=".config/nvim"
MAC_ONLY=("chunkwmrc" "skhdrc")


for f in $(ls config); do
    TARGET="$HOME/.$f"
    if [ $f == "init.vim" ]; then
        mkdir -p $HOME/$NVIM_CONFIG_DIR || true
        TARGET=$HOME/$NVIM_CONFIG_DIR/$f
    fi
    rm -f $TARGET
    ln -sf "$(pwd)/config/$f" $TARGET
    if [ $f == "chunkwmrc" ]; then
        chmod +x $TARGET
    fi
done

if [ $(uname) != "Darwin" ]; then
    for f in $MAC_ONLY; do
        rm ~/.$f
    done
fi
