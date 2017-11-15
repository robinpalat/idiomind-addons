#!/bin/bash
# -*- ENCODING: UTF-8 -*-

act=$(grep -o act=\"[^\"]* "$DC_a/whtr.cfg" |grep -o '[^"]*$')

function hardToRecall() {
    local name log
    img3='/usr/share/idiomind/images/3.png'
    if [ ! -f "${DM_tls}/6.cfg" ]; then
        msg "$(gettext "Do you want to create a topic for words harder to remember?")\n " \
        dialog-question "$(gettext "Practice")" "$(gettext "Yes")" "$(gettext "Not ask again")"
        if [ $? = 0 ]; then
            "$DS/add.sh" new_topic 1 0 "$(gettext "Words harder to remember")"
            echo "$(gettext "Words harder to remember")" > "${DM_tls}/6.cfg"
        elif [ $? = 1 ]; then
            :
        fi
    fi
    name=$(< "${DM_tls}/6.cfg")
    if [[ -d "${DM_tl}/${name}/.conf" ]]; then
        index="$(cat "${DM_tl}/${name}/.conf/1.cfg" "${DM_tl}/${name}/.conf/2.cfg")"
        log="$(cat ./log2 ./log3)"
        echo "${log}" |while read -r trgt; do
            if ! grep -Fxq "${trgt}" "${index}"; then
                item="$(grep -F -m 1 "trgt{${trgt}}" "${DC_tlt}/0.cfg")"
                if [ -n "${item}" ]; then
                    echo "${item}" >> "${DM_tl}/${name}/.conf/0.cfg"
                    echo "${trgt}" >> "${DM_tl}/${name}/.conf/1.cfg"
                    echo "${trgt}" >> "${DM_tl}/${name}/.conf/3.cfg"
                    echo "${trgt}" >> "${DM_tl}/${name}/.conf/practice/log3"
                    echo -e "$img3\n${trgt}\nFALSE" >> "${DM_tl}/${name}/.conf/5.cfg"
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
