#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"
fileconf="$DC_a/whtr.cfg"
named="$(gettext "Hard words to learn")"
label="$(gettext "Collect all words from the second review onwards that are difficult to learn.")\n"

[ ! -f "$fileconf" ] && touch "$fileconf"
if [[ -z "$(< "$fileconf")" ]]; then
    echo -e "act=\"\"\nname=\"${named}\"" > "$fileconf"
fi

act=$(grep -o act=\"[^\"]* "$fileconf" |grep -o '[^"]*$')
name=$(grep -o name=\"[^\"]* "$fileconf" |grep -o '[^"]*$')
[ -z "${name}" ] && name="${named}"
c=$(yad --form --title="$(gettext "Hard words to learn")" \
--name=Idiomind --class=Idiomind \
--text="$label" \
--window-icon=idiomind --align=right --center \
--on-top --skip-taskbar \
--width=400 --height=120 --borders=10 \
--always-print-result --editable --print-all \
--field="$(gettext "Active")":chk "$act" \
--field="$(gettext "Topic name")" "$name" \
--button="$(gettext "Cancel")":1 \
--button="$(gettext "OK")":0)
ret=$?

if [ $ret = 0 ]; then
    echo -e "act=\"$(cut -d "|" -f1 <<< "$c")\"\n\
    name=\"$(cut -d "|" -f2 <<< "$c")\"" > "$fileconf"
fi

exit 0
