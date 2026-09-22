#!/bin/bash
# -*- ENCODING: UTF-8 -*-


if [[ "$name" =~ ^https?://[^[:space:]]+\.[^[:space:]]+$ ]]; then

        
        "$DS/addons/Feeds/feeds.sh" fetch_content "${name}" 1
        
        
 exit 0
fi
