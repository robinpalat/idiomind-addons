#!/bin/bash
# -*- ENCODING: UTF-8 -*-

cd "$(dirname "$0")"

if [[ $1 = 'viewer' ]]; then
    export item="$3"
    ./podcasts.sh viewer & exit
elif [[ $1 = 'remove_item' ]]; then
    ./podcasts.sh remove_item & exit
elif [[ $1 = 'delete_all' ]]; then
    ./podcasts.sh delete_all & exit
elif [[ $1 = 'tasks' ]]; then
    ./podcasts.sh "$@" & exit
elif [[ $1 = 'stop' ]]; then
    if ps -A | pgrep -f "wget -q -c -T 51"; then kill -9 $(pgrep -f "wget -q -c -T 51") & fi
    if ps -A | pgrep -f "podcasts.sh update"; then kill -9 $(pgrep -f "podcasts.sh update") & fi
    exit
else
    ./podcasts.sh & exit
fi
