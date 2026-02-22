#!/usr/bin/env bash

script='
if frontmost of application "Ghostty" then
    tell application "System Events" to tell process "Ghostty" to set visible to not (get visible)
else
    do shell script "open -a /Applications/Ghostty.app"
end if
'
osascript -e "${script}" > /dev/null 2>&1
