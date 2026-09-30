#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"
fileconf="$DC_a/whtr.cfg"
named="$(gettext "Hard words")"

label="$(gettext "This add-on automatically collects words that repeatedly cause difficulty during practice across all your topics.")\n\n\
<b>$(gettext "How does it work?")</b>\n\n\
$(gettext "The collected words are added to a dedicated topic, creating a personalized practice list of the words that need more attention.")\n\n\
<b>$(gettext "Topic name")</b>\n\n\
$(gettext "Specify the name of the topic that will contain the collected words.")\n"


[ ! -f "$fileconf" ] && touch "$fileconf"

act=$(grep -o act=\"[^\"]* "$fileconf" |grep -o '[^"]*$')
name=$(grep -o name=\"[^\"]* "$fileconf" |grep -o '[^"]*$')
[ -z "${name}" ] && name="${named}"
c=$(yad --form --title="$(gettext "Hard words")" \
--name=Idiomind --class=Idiomind \
--text="<big><b>${named}</b></big>\n\n$label" \
--window-icon=idiomind --align=right --center \
--on-top --skip-taskbar \
--width=400 --height=150 --borders=12 \
--always-print-result --editable --print-all \
--field="$(gettext "Active")":chk "$act" \
--field="$(gettext "Topic name")" "$name" \
--field=" ":lbl "" \
--button="$(gettext "Save")!gtk-apply":0 \
--button="$(gettext "Close")":1)
ret=$?

if [ $ret = 0 ]; then
    echo -e "act=\"$(cut -d "|" -f1 <<< "$c")\"" > "$fileconf"
fi

exit 0
