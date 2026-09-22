#!/bin/bash
# -*- ENCODING: UTF-8 -*-

if curl -v www.google.com 2>&1 | grep -m1 "HTTP/1.1" >/dev/null 2>&1; then
    DCP="$DM_tl/Podcasts/.conf"
    if [ -f "$DCP/podcasts.cfg" ]; then
        echo -e "\n--- updating podcasts..."
        if [ "$(grep -o 'update="[^"]*' "$DCP/podcasts.cfg" |grep -o '[^"]*$')" = TRUE ]; then
        ( sleep 1; "$DS_a/Podcasts/podcasts.sh" update 0 ) & fi
        echo -e "\tpodcasts ok\n"
    fi
fi
