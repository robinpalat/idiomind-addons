#!/bin/bash
# -*- ENCODING: UTF-8 -*-

echo -e "\n--- updating feeds..."
if curl -v www.google.com 2>&1 | grep -m1 "HTTP/1.1" >/dev/null 2>&1; then
    ( while read -r item; do
        if [ -f "$DM_tl/${item}/.conf/feeds" -a ! -f "$DM_tl/${item}/.conf/lk" ]; then
            "$DS/ifs/mods/topic/Feeds.sh" fetch_content "${item}"
        fi
    done < <(cd "$DM_tl"; find ./ -maxdepth 1 -mtime -80 \
    -type d -not -path '*/\.*' -exec ls -tNd {} + |sed 's|\./||g;/^$/d')
    
    echo -e "\tfeeds ok\n" ) &
fi


