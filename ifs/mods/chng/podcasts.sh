#!/bin/bash
# -*- ENCODING: UTF-8 -*-

altrau="" # alternative audio player

source /usr/share/idiomind/default/c.conf
file_cfg="${DM_tl}/Podcasts/.conf/podcasts.cfg"
evideo="$(grep -oP '(?<=evideo=\").*(?=\")' "${file_cfg}")"
eaudio="$(grep -oP '(?<=eaudio=\").*(?=\")' "${file_cfg}")"
ekeep="$(grep -oP '(?<=ekeep=\").*(?=\")' "${file_cfg}")"
altrvi="$(grep -oP '(?<=altrvi=\").*(?=\")' "${file_cfg}")"

check_alt_player () {
    if [ -n "$1" ]; then
        if ! which "$1" >/dev/null; then
            sleep 2
            source "$DS/ifs/cmns.sh"
            msg "$(gettext "The specified path for the video player does not exist")" info
            "$DS/stop.sh" 2 &
        fi
    fi
}

if [ -d $DT ]; then find $DT -maxdepth 1 \
-type f -name '*.m3u' -exec rm -fr {} \;; fi

DMC="$DM_tl/Podcasts/cache"
DPC="$DM_tl/Podcasts/.conf"
export stnrd=0
f=0

play_itep() {
    [ ${mime} = 1 ] && notify-send -i "${icon}" "${trgt}" "${srce}" -t 5000 &
    "$DS/play.sh" play_file "${file}" "${trgt}"
}
            
get_itep() {
    unset trgt srce icon stnrd file mime
    if [ ${f} -gt 5 ] || [ ! -d "${DM_tl}/Podcasts/cache" ]; then
        source "$DS/ifs/cmns.sh"
        msg "$(gettext "An error has occurred. Playback stopped")" dialog-information &
        "$DS/stop.sh" 2
    fi
    fname=$(echo -n "${item}" |md5sum |rev |cut -c 4- |rev)
    item="$DM_tl/Podcasts/cache/$fname.item"
    if [ -f "${item}" ]; then
        channel="$(grep -o channel=\"[^\"]* "${item}" |grep -o '[^"]*$')"
        title="$(grep -o title=\"[^\"]* "${item}" |grep -o '[^"]*$')"
        if [ -e "$DMC/$fname.mp3" ]; then file="$DMC/$fname.mp3"; mime=1
        elif [ -e "$DMC/$fname.ogg" ]; then file="$DMC/$fname.ogg"; mime=1
        elif [ -e "$DMC/$fname.m4v" ]; then file="$DMC/$fname.m4v"; mime=2
        elif [ -e "$DMC/$fname.m4a" ]; then file="$DMC/$fname.m4a"; mime=2
        elif [ -e "$DMC/$fname.mp4" ]; then file="$DMC/$fname.mp4"; mime=2
        elif [ -e "$DMC/$fname.avi" ]; then file="$DMC/$fname.avi"; mime=2; fi
        if [ -e "${file}" ]; then
            trgt="${title}"
            srce="$(gettext "By:") ${channel}"
            icon=idiomind
        else 
            let f++
        fi
    else
        let f++
    fi
    export trgt srce icon stnrd file mime
}

video_file() {
    fname=$(echo -n "${2}" |md5sum |rev |cut -c 4- |rev)
    if [ -e "$DMC/$fname.m4v" ]; then
    [ $1 = 0 ] && echo "$DMC/$fname.m4v" || echo "$2"; fi
    if [ -e "$DMC/$fname.mp4" ]; then
    [ $1 = 0 ] && echo "$DMC/$fname.mp4" || echo "$2"; fi
    if [ -e "$DMC/$fname.m4a" ]; then
    [ $1 = 0 ] && echo "$DMC/$fname.m4a" || echo "$2"; fi
}

audio_file() {
    fname=$(echo -n "${2}" |md5sum |rev |cut -c 4- |rev)
    if [ -f "$DMC/$fname.mp3" ]; then
    [ $1 = 0 ] && echo "$DMC/$fname.mp3" || echo "$2"
    fi
}

if [ "$1" = "_video_" ]; then
    if [ -n "${altrvi}" ]; then
        check_alt_player "${altrvi}" &
        while read -r item; do
            video_file 0 "$item" >> "$DT/list.m3u"
        done < "$DPC/watch.tsk"
        sed -i '/^$/d' "$DT/list.m3u"
        echo "$(gettext "Podcast playlist")" > "$DT/playlck"
        echo "0" > "$DT/playlck"
        ${altrvi} "$DT/list.m3u" &
    else
        sleep 1
        while read -r item; do
            _stop=1; video_file 0 "$item" >> "$DT/list.m3u"
        done < "$DPC/watch.tsk"
        echo "$(gettext "Podcast playlist")" > "$DT/playlck"
        mplayer -noconsolecontrols -name Idiomind \
        -title "Idiomind (mplayer)" \
        -playlist "$DT/list.m3u"; wait
    fi
    
    if [ -d $DT ]; then find $DT -maxdepth 1 \
    -type f -name '*.m3u' -exec rm -fr {} \;; fi
    
    echo "1" > "$DT/playlck"
    exit 0

elif [ "$1" = "_audio_" ]; then
    if [ -n "${altrau}" ]; then
        check_alt_player "${altrau}" &
        while read -r item; do
            audio_file 0 "$item" >> "$DT/list.m3u"
        done < "$DPC/listen.tsk"
        echo "$(gettext "Podcast playlist")" > "$DT/playlck"
        ${altrau} "$DT/list.m3u" &
    else
        sleep 1
        while read -r item; do get_itep
            [ "$(< "$DT/playlck")" = 0 ] && break
            echo "${trgt}" > "$DT/playlck"
            _stop=1; play_itep; sleep 2
        done < "$DPC/listen.tsk"
    fi
    
    if [ -d $DT ]; then find $DT -maxdepth 1 \
    -type f -name '*.m3u' -exec rm -fr {} \;; fi
    
    echo "0" > "$DT/playlck"
    exit 0
    
elif [ "$1" = "_favs_" ]; then
    if [ -z "${altrau}" -a -z "${altrvi}" ]; then
        check_alt_player "${altrvi}" &
        check_alt_player "${altrau}" &
        sleep 1
        while read -r item; do get_itep
            [ "$(< "$DT/playlck")" == 0 ] && break
            echo "$trgt" > "$DT/playlck"
            _stop=1; play_itep; sleep 2
        done < "$DPC/2.lst"
    else
        if [ -n "${altrau}" ]; then
            check_alt_player "${altrau}" &
            while read -r item; do
                audio_file 0 "$item" >> "$DT/list.m3u"
            done < "$DPC/2.lst"
            sed -i '/^$/d' "$DT/list.m3u"
            echo "$(gettext "Podcast playlist")" > "$DT/playlck"
            ${altrau} "$DT/list.m3u" &
        else
            sleep 1
            while read -r item; do
                audio_file 1 "$item" >> "$DT/list.m3u"
            done < "$DPC/2.lst"
            while read -r item; do get_itep
                [ "$(< "$DT/playlck")" == 0 ] && break
                echo "$trgt" > "$DT/playlck"
                _stop=1; play_itep; sleep 2
            done < "$DT/list.m3u"
        fi
        if [ -n "${altrvi}" ]; then
            check_alt_player "${altrvi}" &
            while read -r item; do
                video_file 0 "$item" >> "$DT/list.m3u"
            done < "$DPC/2.lst"
            sed -i '/^$/d' "$DT/list.m3u"
            echo "$(gettext "Podcast playlist")" > "$DT/playlck"
            ${altrvi} "$DT/list.m3u" &
        else
            sleep 1
            while read -r item; do
                video_file 1 "$item" >> "$DT/list.m3u"
            done < "$DPC/2.lst"
            while read -r item; do get_itep
                [ "$(< "$DT/playlck")" == 0 ] && break
                echo "$trgt" > "$DT/playlck"
                _stop=1; play_itep; sleep 2
            done < "$DT/list.m3u"
        fi
    fi
    
    if [ -d $DT ]; then find $DT -maxdepth 1 \
    -type f -name '*.m3u' -exec rm -fr {} \;; fi
    
    echo "1" > "$DT/playlck"
    exit 0
fi



if [[ ${evideo} = TRUE ]] || [[ ${eaudio} = TRUE ]] || [[ ${ekeep} = TRUE ]]; then

    if [ ${ekeep} = TRUE ]; then
        if [ -z "${altrau}" -a -z "${altrvi}" ]; then
            check_alt_player "${altrvi}" &
            check_alt_player "${altrau}" &
            sleep 1
            while read -r item; do get_itep
                echo "$trgt" > "$DT/playlck"
                _stop=1; _play; sleep 2
            done < "$DPC/2.lst"
        else
            if [ -n "${altrau}" ]; then
                check_alt_player "${altrau}" &
                while read -r item; do
                    audio_file 0 "$item" >> "$DT/list.m3u"
                done < "$DPC/2.lst"
                sed -i '/^$/d' "$DT/list.m3u"
                echo "$(gettext "Podcast playlist")" > "$DT/playlck"
                ${altrau} "$DT/list.m3u"
            else
                sleep 1
                while read -r item; do
                    audio_file 1 "$item" >> "$DT/list.m3u"
                done < "$DPC/2.lst"
                while read -r item; do get_itep
                    echo "$trgt" > "$DT/playlck"
                    _stop=1; _play; sleep 2
                done < "$DT/list.m3u"
            fi
            if [ -n "${altrvi}" ]; then
                check_alt_player "${altrvi}" &
                while read -r item; do
                    video_file 0 "$item" >> "$DT/list.m3u"
                done < "$DPC/2.lst"
                sed -i '/^$/d' "$DT/list.m3u"
                echo "$(gettext "Podcast playlist")" > "$DT/playlck"
                ${altrvi} "$DT/list.m3u"
            else
                sleep 1
                while read -r item; do
                    video_file 1 "$item" >> "$DT/list.m3u"
                done < "$DPC/2.lst"
                while read -r item; do get_itep
                    echo "$trgt" > "$DT/playlck"
                    _stop=1; _play; sleep 2
                done < "$DT/list.m3u"
            fi
        fi
         if [ -d $DT ]; then find $DT -maxdepth 1 \
        -type f -name '*.m3u' -exec rm -fr {} \;; fi
    fi
    if [ ${eaudio} = TRUE ]; then

        if [ -n "${altrau}" ]; then
            check_alt_player "${altrau}" &
            while read -r item; do
                audio_file 0 "$item" >> "$DT/list.m3u"
            done < "$DPC/1.lst"
            echo "$(gettext "Podcast playlist")" > "$DT/playlck"
            ${altrau} "$DT/list.m3u"
        else
            sleep 1
            while read -r item; do get_itep
                echo "${trgt}" > "$DT/playlck"
                _stop=1; _play; sleep 2
            done < "$DPC/1.lst"
        fi
         if [ -d $DT ]; then find $DT -maxdepth 1 \
        -type f -name '*.m3u' -exec rm -fr {} \;; fi
    fi
    if [ ${evideo} = TRUE ]; then
        if [ -n "${altrvi}" ]; then
            check_alt_player "${altrvi}" &
            while read -r item; do
                video_file 0 "$item" >> "$DT/list.m3u"
            done < "$DPC/1.lst"
            sed -i '/^$/d' "$DT/list.m3u"
            echo "$(gettext "Podcast playlist")" > "$DT/playlck"
            ${altrvi} "$DT/list.m3u"
        else
            sleep 1
            while read -r item; do
                _stop=1; video_file 0 "$item" >> "$DT/list.m3u"
            done < "$DPC/1.lst"
            echo "$(gettext "Podcast playlist")" > "$DT/playlck"
            mplayer -noconsolecontrols -name Idiomind \
            -title "Idiomind (mplayer)" \
            -playlist "$DT/list.m3u"; wait
        fi
         if [ -d $DT ]; then find $DT -maxdepth 1 \
        -type f -name '*.m3u' -exec rm -fr {} \;; fi
    fi
fi
