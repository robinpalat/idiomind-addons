#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
link='https://console.developers.google.com'
DC_a="$HOME/.config/idiomind/addons"
if [ ! -f "$DC_a/gtts.cfg" ] || [[ -z "$(< "$DC_a/gtts.cfg")" ]]; then
echo -e "ini=\"a\"\nkey=\"\"" > "$DC_a/gtts.cfg"; fi
ini=$(grep -o ini=\"[^\"]* "$DC_a/gtts.cfg" |grep -o '[^"]*$')
key=$(grep -o key=\"[^\"]* "$DC_a/gtts.cfg" |grep -o '[^"]*$')
c=$(yad --form --title="$(gettext "Speech to text")" \
--name=Idiomind --class=Idiomind \
--text="This script makes use of Google's speech recognition engine in order to try recognize speech from MP3 audio files. You can invoke this function by entering a single character into the text box from dialog New note." \
--window-icon=idiomind --align=right --center \
--on-top --skip-taskbar --expand-column=3 \
--width=450 --height=250 --borders=5 \
--always-print-result --editable --print-all \
--field="\t$(gettext "Use this character to invoke:")" "$ini" \
--field="Key" "$key" \
--field="For this feature you need to provide a key. Please get one from: <a href='$link'>wwww.console.developers.google.com</a>":lbl " " \
--button="$(gettext "Cancel")":1 \
--button="$(gettext "OK")":0)
ret=$?
if [[ $ret = 0 ]]; then
val1="$(cut -d "|" -f1 <<<"$c")"
val2="$(cut -d "|" -f2 <<<"$c")"
sed -i "s/ini=.*/ini=\"$val1\"/g" "$DC_a/gtts.cfg"
sed -i "s/key=.*/key=\"$val2\"/g" "$DC_a/gtts.cfg"
fi
exit 0
