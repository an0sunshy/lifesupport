#!/usr/bin/env bash

script='
if frontmost of application "kitty" then
    tell application "System Events" to tell process "kitty" to set visible to not (get visible)
else
    do shell script "open -a /Applications/kitty.app"
end if
'
osascript -e "${script}" > /dev/null 2>&1
