#!/bin/bash
# -*- ENCODING: UTF-8 -*-

source /usr/share/idiomind/default/c.conf
file_cfg="${DM_tl}/Podcasts/.conf/podcasts.cfg"
evideo="$(grep -oP '(?<=evideo=\").*(?=\")' "${file_cfg}")"
eaudio="$(grep -oP '(?<=eaudio=\").*(?=\")' "${file_cfg}")"
e_keep="$(grep -oP '(?<=e_keep=\").*(?=\")' "${file_cfg}")"
altrau="$(grep -oP '(?<=altrau=\").*(?=\")' "${file_cfg}")"
altrvi="$(grep -oP '(?<=altrvi=\").*(?=\")' "${file_cfg}")"
[ -d "$DT"/ ] && find "$DT"/ -maxdepth 1 -type f -name '*.m3u' -exec rm -fr {} \;
DMC="$DM_tl/Podcasts/cache"
DPC="$DM_tl/Podcasts/.conf"
export stnrd=0
f=0

get_itep() {
    unset trgt srce icon stnrd file mime
    if [ ${f} -gt 5 -o ! -d "${DM_tl}/Podcasts/cache" ]; then
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


if [ -e "$DT/play2lck" ]; then
    item="$(cat "$DT/play2lck")"
    fname=$(echo -n "${item}" |md5sum |rev |cut -c 4- |rev)
    if [ -f "$DMC/$fname.mp3" ]; then
        echo "${item}" > "$DT/playlck"
        echo "${item}" > "$DT/play2lck"
        "$DS"/play.sh play_file "$DMC/$fname.mp3" "${item}"
        [ -e "$DT/playlck" ] && echo 0 > "$DT/playlck"
    else
        notify-send -i "idiomind" "$(gettext "No such file or directory")" "${epi}" -t 5000; exit 1
    fi

elif [[ ${evideo} = TRUE ]] || [[ ${eaudio} = TRUE ]] || [[ ${e_keep} = TRUE ]]; then

    video_file() {
            fname=$(echo -n "${2}" |md5sum |rev |cut -c 4- |rev)
            if [ -e "$DMC/$fname.m4v" ]; then
            [ $1 = 0 ] && echo "$DMC/$fname.m4v" || echo "$2"; fi
            if [ -e "$DMC/$fname.mp4" ]; then
            [ $1 = 0 ] && echo "$DMC/$fname.mp4" || echo "$2"; fi
    }
    audio_file() {
            fname=$(echo -n "${2}" |md5sum |rev |cut -c 4- |rev)
            if [ -f "$DMC/$fname.mp3" ]; then
            [ $1 = 0 ] && echo "$DMC/$fname.mp3" || echo "$2"
            fi
    }
    
    if [ ${e_keep} = TRUE ]; then
        if [ -z "${altrau}" -a -z "${altrvi}" ]; then
            sleep 1
            while read -r item; do get_itep
                echo "$trgt" > "$DT/playlck"
                _stop=1; _play; sleep 2
            done < "$DPC/2.lst"
        else
            if [ -n "${altrau}" ]; then
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
        find $DT -maxdepth 1 -type f -name '*.m3u' -exec rm -fr {} \;
    fi
    if [ ${eaudio} = TRUE ]; then

        if [ -n "${altrau}" ]; then
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
        find $DT -maxdepth 1 -type f -name '*.m3u' -exec rm -fr {} \;
    fi
    if [ ${evideo} = TRUE ]; then

        if [ -n "${altrvi}" ]; then
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
            -title "${c} $(gettext "videos") - mplayer" \
            -playlist "$DT/list.m3u"; wait
        fi
        find $DT -maxdepth 1 -type f -name '*.m3u' -exec rm -fr {} \;
    fi

fi
