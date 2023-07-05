#!/bin/bash
# -*- ENCODING: UTF-8 -*-


source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"

fetch_content() {
    export tpe="${2}"

    DC_tlt="$DM_tl/${tpe}/.conf"
    itemdir=$(base64 <<< $((RANDOM%100000)) | head -c 32)
    export DT_r="$DT/$itemdir"
    if [[ $(wc -l < "${DC_tlt}/data") -ge 200 ]]; then exit 1; fi
    if [ -e "$DT/updating_feeds" ]; then
        exit 1
    else
        > "$DT/updating_feeds"
    fi
    for t in {0..30}; do
        curl -v www.google.com 2>&1 \
        | grep -m1 "HTTP/1.1" >/dev/null 2>&1 && break ||sleep 10
        [ ${t} = 30 ] && exit 1
    done
 
    cat "${DC_tlt}/feeds" |while read -r _feed; do
        if [ -n "${_feed}" ]; then
         
            wget -O "$DT/out.xml" "${_feed}"
            feed_items="$(xsltproc "$DS/default/tmpl.xml" "$DT/out.xml")"
            if [ -z "${feed_items}" ]; then internet; fi
            feed_items="$(echo "${feed_items}" |tr '\n' '*' |tr -s '[:space:]' |sed 's/EOL/\n/g' |head -n2)"
            feed_items="$(echo "${feed_items}" |sed '/^$/d')"
            while read -r item; do
            
                if [[ $(wc -l < "${DC_tlt}/data") -ge 200 ]]; then exit 1; fi
                fields="$(echo "${item}" |sed -r 's|-\!-|\n|g')"
                title=$(echo "${fields}" |sed -n 3p \
                |iconv -c -f utf8 -t ascii |sed 's/\://g' \
                |sed 's/\&/&amp;/g' |sed 's/^\s*./\U&\E/g' \
                |sed 's/<[^>]*>//g' |sed 's/^ *//; s/ *$//; /^$/d')
                export link="$(echo "${fields}" |sed -n 4p \
                |sed 's|/|\\/|g' |sed 's/\&/\&amp\;/g')"
                if [ -n "${title}" ]; then
                    if ! grep -Fo "trgt{${title^}}" "${DC_tlt}/data" >/dev/null 2>&1 && \
                    ! grep -Fxq "${title^}" "${DC_tlt}/exclude" >/dev/null 2>&1; then
                        export trans='TRUE'
                        export trgt="${title^}"
                        export tpe
                        echo "${trgt}" >> "$DT/updating_feeds"
                        "$DS/add.sh" new_item "${tpe}"
                    fi
                fi
            done <<< "${feed_items}"
        fi
        cleanups "$DT/out.xml"
    done
    if [[ ${3} = 1 ]] && [[ $(wc -l < "$DT/updating_feeds") = 0 ]]; then
        notify-send -i idiomind \
        "$(gettext "Feeds for") \"${tpc}\"" \
        "$(gettext "No new content")" -t 8000
    fi
    cleanups "$DT/updating_feeds" 
    return 0
} >/dev/null 2>&1


case "$1" in
    fetch_content)
    fetch_content "$@" ;;
esac



