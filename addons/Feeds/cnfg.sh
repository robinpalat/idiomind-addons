#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"

name="$(gettext "Rss feeds content")"
label="$(gettext "Does not need configuration.")"

c=$(yad --form --title="$name" \
--name=Idiomind --class=Idiomind \
--text="<b>$name</b>\n$label" \
--window-icon=idiomind --align=right --center \
--on-top --skip-taskbar \
--width=400 --borders=10 \
--always-print-result --editable --print-all \
--button="$(gettext "Close")":1)
ret=$?

exit 0
