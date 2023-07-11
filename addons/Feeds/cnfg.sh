#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"


function edit_feeds_list() {
    yad --list --title="$tpc" \
    --text="<small>$(gettext "Add or remove feed urls:")</small>" \
    --name=Idiomind --class=Idiomind \
    --editable --separator='\n' \
    --always-print-result --print-all \
    --window-icon=idiomind \
    --limit=3 --no-headers --center \
    --width=520 --height=140 --borders=10 \
    --column="" \
    "$btnf" --button="$(gettext "Save")":0 \
    --button="$(gettext "Cancel")":1
    
}

edit_feeds() {
    file="$DM_tl/${tpc}/.conf/feeds"
    feeds="$(< "${file}")"
    if [ -n "$feeds" ]; then 
        btnf="--button="$(gettext "Update")":2"
    else
        btnf="--center"
    fi
    export btnf
    mods="$(echo "${feeds}" |edit_feeds_list)"
    ret="$?"
    if [ $ret != 1 -a $ret -le 2 ]; then
        if [ -z "${mods}" ]; then
            cleanups "${file}" "$DM_tl/${tpc}/.conf/exclude"
        elif [ "${feeds}" != "${mods}" ]; then
            touch "$DM_tl/${tpc}/.conf/exclude"
            echo "${mods}" |sed -e '/^$/d' > "${file}"
            "$DS/ifs/mods/topic/Feeds.sh" fetch_content "${tpc}" 1 &
        fi
        if [ $ret = 2 ]; then
        
            "$DS/ifs/mods/topic/Feeds.sh" fetch_content "${tpc}" 1 &
        fi
    fi
} >/dev/null 2>&1





tpcs="$(cdb "${shrdb}" 5 topics)"
tpcs="$(grep -vFx "${tpe}" <<< "$tpcs" |tr "\\n" '!' |sed 's/\!*$//g')"
[ -n "$tpcs" ] && export e='!'
name="$(gettext "Feeds")"
label="$(gettext "Automatically add content to your topics through feeds.")\n\n <small>$(gettext "Select topic to manage:")</small>"

c=$(yad --form --title="$name" \
--name=Idiomind --class=Idiomind \
--text="\n$label" \
--field=""":CB" "!$tpe$e$tpcs" \
--window-icon=idiomind --align=right --center \
--on-top --skip-taskbar \
--width=400 --borders=12 \
--always-print-result --editable --print-all \
--button="$(gettext "Select")":0 \
--button="$(gettext "Close")":1)

ret=$?

        if [ ${ret} -eq 0 ]; then
			tpc="$(cut -d "|" -f1 <<< "${c}")"
			if [ -z "$tpc" ];then exit 0
			else
				edit_feeds 
			fi
        fi

exit 0
