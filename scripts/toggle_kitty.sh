#!/usr/bin/env bash

if ! pgrep -f "kitty" > /dev/null 2>&1; then
    open -a "/Applications/kitty.app"
else
    script='
    tell application "System Events" to set isVisible to visible of application process "kitty"

    if isVisible then
        tell application "System Events" to tell process "kitty" to set visible to not (get visible)
    else
        do shell script "open -a /Applications/kitty.app"
    end if
    '
    osascript -e "${script}" > /dev/null 2>&1
fi
