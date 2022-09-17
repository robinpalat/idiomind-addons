#!/bin/bash
# -*- ENCODING: UTF-8 -*-

cd "$(dirname "$0")"
source /usr/share/idiomind/default/c.conf
date=$(date +%d)

if [[ $1 = 'viewer' ]]; then
    export item="$3"
    ./podcasts.sh viewer & exit
elif [[ $1 = 'optns' ]]; then
    ./podcasts.sh dlg_optns & exit
elif [[ $1 = 'subs' ]]; then
    ./podcasts.sh dlg_subs & exit
elif [[ $1 = 'remove_item' ]]; then
    ./podcasts.sh remove_item & exit
elif [[ $1 = 'delete_all' ]]; then
    ./podcasts.sh delete_all & exit
elif [[ $1 = 'tasks' ]]; then
    ./podcasts.sh "$@" & exit
elif [[ $1 = 'stop' ]]; then
    if ps -A | pgrep -f "wget -q -c -T 51"; then 
        kill -9 $(pgrep -f "wget -q -c -T 51") &
    fi
    if ps -A | pgrep -f "podcasts.sh update"; then 
        kill -9 $(pgrep -f "podcasts.sh update") &
    fi
    exit 0
else
    source "$DS/ifs/cmns.sh"
    f=0
    check_dir "$DM_tl/Podcasts" "$DM_tl/Podcasts/.conf" "$DM_tl/Podcasts/cache"
    if [ ! -f "$DM_tl/Podcasts/.conf/stts" ]; then f=1
    else 
        [ $(< "$DM_tl/Podcasts/.conf/stts") != 11 ] && f=1
    fi
    if [ ${f} = 1 ]; then
        cd "$DM_tl/Podcasts/.conf/"
        touch "./podcasts.cfg" "./1.lst" "./2.lst" "./feeds.lst" "./old.lst"
        echo 11 > "$DM_tl/Podcasts/.conf/stts"
        echo -e "\n$(gettext "Latest downloads:") 0" > "$DM_tl/Podcasts/$date.updt"
        > "$DM_tl/Podcasts/cache/.CACHEDIR"
        > "$DM_tl/Podcasts/$date.updt"
        > "$DM_tl/Podcasts/.conf/podcasts.cfg"
        sets=( 'update' 'sync' 'synf' 'path' 'eaudio' 'evideo' 'ekeep' 'altrvi' )
        n=0
        while [ ${n} -le 7 ]; do
            echo -e "${sets[${n}]}=\"FALSE\"" >> "$DM_tl/Podcasts/.conf/podcasts.cfg"
            ((n=n+1))
        done
        "$DS/mngr.sh" mkmn 0
    fi
    "$DS/ifs/tpc.sh" 'Podcasts' 11 & exit 0
fi
