#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"


fileconf="$DC_a/SaveAsAudio.cfg"
named="$(gettext "Save as audio")"

named="$(gettext "Save as audio")"

label="$(gettext "Exports the words and sentences of a topic as a single MP3 for listening and practice outside Idiomind.")\n\n\
<b>$(gettext "Pronunciation recall")</b>\n\n\
$(gettext "Adds pauses and sound cues after each item, giving you time to repeat aloud what you have just heard.")\n"

[ ! -f "$fileconf" ] && touch "$fileconf"

act=$(grep -o act=\"[^\"]* "$fileconf" |grep -o '[^"]*$')

[ -z "$act" ] && act="TRUE"

c=$(yad --form --title="$(gettext "${named}")" \
--name=Idiomind --class=Idiomind \
--window-icon=idiomind --center \
--on-top --skip-taskbar \
--width=400 --height=150 --borders=12 \
--print-column=4 \
--field="<big><b>${named}</b></big>\n":lbl "" \
--field="$label":lbl "" \
--field=" ":lbl "" \
--field="$(gettext "Add pronunciation recall practice")":chk "$act" \
--button="$(gettext "Save")!gtk-apply":0 \
--button="$(gettext "Close")":1)
ret=$?

c=$(printf '%s' "$c" | cut -d'|' -f4)

if [ "$ret" = 0 ]; then
    printf 'act="%s"\n' "$c" > "$fileconf"
fi

exit 0
