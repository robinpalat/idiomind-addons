#!/bin/bash
# -*- ENCODING: UTF-8 -*-
# Feeds.sh

source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DSP="$DS_a/Feeds"

create_from_feed() {


    feed_url="${1}"

    # Verificar conexión
    internet

    # Descargar el recurso
    itemdir=$(base64 <<< $((RANDOM%100000)) | head -c 32)
    DT_f="$DT/$itemdir"
    check_dir "$DT_f"

if ! wget -q -O "$DT_f/feed.xml" "$feed_url"; then
    cleanups "$DT_f"
    msg "$(gettext "Feed not found.")\n" \
        dialog-information "$(gettext "Information")"
    return 1
fi

	feed_info="$(xsltproc "$DSP/chnl.xml" "$DT_f/feed.xml" 2>/dev/null)"

	feed_title="${feed_info%%-!-*}"


    if [ -z "$feed_title" ]; then
        cleanups "$DT_f"
        msg "$(gettext "Feed not found.")\n" \
            dialog-information "$(gettext "Information")"
        return 1
    fi

    # Mostrar el nombre encontrado y pedir confirmación.
    msg "$(gettext "Feed found:")\n\n${feed_title}\n\n$(gettext "Do you want to create this topic?")" \
        dialog-question "$(gettext "Add feed")"

    if [ $? -ne 0 ]; then
        cleanups "$DT_f"
        return 1
    fi

    # Crear el topic usando el mecanismo normal de add.sh.
    "$DS/add.sh" new_topic 1 1 "$feed_title"

    # Si la creación tuvo éxito, configurar el feed.
    if [ -d "$DM_tl/$feed_title/.conf" ]; then
        printf '%s\n' "$feed_url" > "$DM_tl/$feed_title/.conf/feeds"

        # Primer fetch.
        fetch_content fetch_content "$feed_title" 1
    fi

    cleanups "$DT_f"
}


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
            feed_items="$(xsltproc "$DSP/tmplt.xml" "$DT/out.xml")"
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
                    # Feed titles are normalized by add.sh before storage, so
                    # the link is the stable identity for duplicate detection.
                    feed_exists=FALSE
                    if [ -n "${link}" ] && grep -Fq "link{${link}}" "${DC_tlt}/data"; then
                        feed_exists=TRUE
                    elif grep -Fo "trgt{${title^}}" "${DC_tlt}/data" >/dev/null 2>&1; then
                        feed_exists=TRUE
                    fi
                    if [[ ${feed_exists} = FALSE ]] && \
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


function tasks() {
	
	"$DS/ifs/extensions/start/update_feeds.sh"
	 
} >/dev/null 2>&1



case "$1" in

    tasks)
        tasks "$@"
        ;;

    fetch_content)
        case "$3" in
            1)
                create_from_feed "$2"
                ;;
            2)
                fetch_content "$@"
                ;;
            *)
                fetch_content "$@"
                ;;
        esac
        ;;

esac
