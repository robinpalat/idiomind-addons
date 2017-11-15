#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"
if [ ! -f "$DC_a/whtr.cfg" ] || [[ -z "$(< "$DC_a/whtr.cfg")" ]]; then
echo -e "act=\"a\"\npss=\"\"" > "$DC_a/whtr.cfg"; fi
act=$(grep -o act=\"[^\"]* "$DC_a/whtr.cfg" |grep -o '[^"]*$')

c=$(yad --form --title="$(gettext "Words Hardest to remember")" \
--name=Idiomind --class=Idiomind \
--text="This script is based in practice results to automatically add the words that are most difficult to learn in a topic." \
--window-icon=idiomind --align=right --center \
--on-top --skip-taskbar --expand-column=3 \
--width=400 --height=120 --borders=5 \
--always-print-result --editable --print-all \
--field="Active":chk "$act" \
--button="$(gettext "Cancel")":1 \
--button="$(gettext "OK")":0)
ret=$?
if [[ $ret = 0 ]]; then
val1="$(cut -d "|" -f1 <<<"$c")"
sed -i "s/act=.*/act=\"$val1\"/g" "$DC_a/whtr.cfg"
fi
exit 0
