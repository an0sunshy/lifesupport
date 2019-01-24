#!/bin/sh

NVIM_CONFIG_DIR=".config/nvim"


for f in $(ls config); do
    TARGET="$HOME/.$f"
    if [ $f == "init.vim" ]; then
        mkdir --parent $HOME/$NVIM_CONFIG_DIR || true
        TARGET=$HOME/$NVIM_CONFIG_DIR/$f
    fi
    rm -f $TARGET
    ln -sf "$(pwd)/config/$f" $TARGET
done
