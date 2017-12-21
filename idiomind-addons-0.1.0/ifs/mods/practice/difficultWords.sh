#!/bin/bash
# -*- ENCODING: UTF-8 -*-

name="$(gettext "Words harder to remember")"
! [ "$DC_a/whtr.cfg" ] && touch "$DC_a/whtr.cfg"
act=$(grep -o act=\"[^\"]* "$DC_a/whtr.cfg" |grep -o '[^"]*$')
nameu="$(grep -o name=\"[^\"]* "$DC_a/whtr.cfg" |grep -o '[^"]*$')"

function hardToRecall() {
    local name log
    
    img3='/usr/share/idiomind/images/3.png'
    if [ ! -f "${DM_tls}/$name" ]; then
        msg "$(gettext "Do you want to create a topic for words harder to remember?")\n " \
        dialog-question "$(gettext "Practice")" "$(gettext "Yes")" "$(gettext "Not ask again")"
        if [ $? = 0 ]; then
            "$DS/add.sh" new_topic 1 0 "$name"
        elif [ $? = 1 ]; then
            return
        fi
    fi
    if [[ -d "${DM_tl}/${name}/.conf" ]]; then
        cfg2="$(tpc_db 5 learnt)"
        index="$(echo "${cfg1}${cfg2}")"
        log="$(cat ./log2 ./log3)"
        
        echo "${log}" |while read -r trgt; do
            if ! grep -Fxq "${trgt}" <<< "${index}"; then
                item="$(grep -F -m 1 "trgt{${trgt}}" "${DC_tlt}/data")"
                if [ -n "${item}" ]; then
                    echo "${item}" >> "${DM_tl}/${name}/.conf/data"
                    echo "${trgt}" >> "${DM_tl}/${name}/.conf/practice/log3"
                fi
            fi
        done
    fi
}

( if [[ "$repass" -ge 0 ]] && [[ "${pr}" != e ]] && [[ "${act}" = TRUE ]]; then
    if [[ "${hard}" -gt 0 ]] || [[ "${ling}" -gt 0 ]]; then
        sleep 2; hardToRecall
    fi
fi ) &
