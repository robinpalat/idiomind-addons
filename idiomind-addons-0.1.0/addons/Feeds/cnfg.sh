#!/bin/bash
# -*- ENCODING: UTF-8 -*-

cd "$(dirname "$0")"

if [[ $1 = 'viewer' ]]; then
    export item="$3"
    ./feeds.sh viewer & exit
elif [[ $1 = 'remove_item' ]]; then
    ./feeds.sh remove_item & exit
elif [[ $1 = 'delete_all' ]]; then
    ./feeds.sh delete_all & exit
elif [[ $1 = 'tasks' ]]; then
    ./feeds.sh "$@" & exit
elif [[ $1 = 'stop' ]]; then
    if ps -A | pgrep -f "wget -q -c -T 51"; then kill -9 $(pgrep -f "wget -q -c -T 51") & fi
    if ps -A | pgrep -f "feeds.sh update"; then kill -9 $(pgrep -f "feeds.sh update") & fi
    exit
else
    ./feeds.sh & exit
fi
