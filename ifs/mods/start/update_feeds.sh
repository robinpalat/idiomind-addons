#!/bin/bash
# -*- ENCODING: UTF-8 -*-
source /usr/share/idiomind/default/c.conf
DCF="$DM_tl/Feeds/.conf"
update="$(grep -o 'update="[^"]*' "$DC_a/feeds.cfg" | grep -o '[^"]*$')"


if [ -f "$DC_a/Feeds${tlng}_tsk" ]; then
	rm -f "$DC_a/Feeds${tlng}_tsk"
fi

if [[ "$update" = TRUE || "$1" == 'UPDT' ]]; then


    echo -e "\n--- updating feeds..."

    if curl -v www.google.com 2>&1 | grep -m1 "HTTP/1.1" >/dev/null 2>&1; then
        (
            while read -r item; do
                if [ -f "$DM_tl/${item}/.conf/feeds" ] &&
                   [ ! -f "$DM_tl/${item}/.conf/lk" ]; then

                    "$DS/addons/Feeds/feeds.sh" fetch_content "${item}"

                fi
            done < <(
                cd "$DM_tl"
                find ./ -maxdepth 1 -mtime -80 \
                    -type d -not -path '*/\.*' \
                    -exec ls -tNd {} + |
                    sed 's|\./||g;/^$/d'
            )

            echo -e "\tfeeds ok\n"
        ) &
    fi

    (
        sleep 50
        echo "$(gettext "Update Topics from Feeds")" > "$DC_a/Feeds${tlng}_tsk"
        idiomind tasks
    ) &
    
    
elif [ "$update" = FALSE ]; then

    echo "$(gettext "Update Topics from Feeds")" > "$DC_a/Feeds${tlng}_tsk"
    idiomind tasks


fi
