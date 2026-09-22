#!/bin/bash
# -*- ENCODING: UTF-8 -*-

if [[ $1 = 'tasks' ]]; then

	"$DS/ifs/extensions/start/update_feeds.sh" 'UPDT'

else
	DC_a="$HOME/.config/idiomind/addons"
	fileconf="$DC_a/feeds.cfg"
	name="Feeds"

	[ ! -f "$fileconf" ] && touch "$fileconf"


label="<b>$(gettext "Feeds")</b>\n\n\
$(gettext "Feeds makes it possible to automatically add content to a topic based on updates from a feed.")\n\n\
<b>$(gettext "How does it work?")</b>\n\n\
$(gettext "When creating a topic, instead of entering its name, simply enter the exact URL of the feed. Idiomind will automatically find the channel name, create the topic with that name, and configure it to receive content from that URL.")\n\n\
$(gettext "From that moment on, Feeds will check for updates and automatically add new content to the topic.")\n"


	act=$(grep -o update=\"[^\"]* "$fileconf" |grep -o '[^"]*$')

	c=$(yad --form --title="$(gettext "$name")" \
	--name=Idiomind --class=Idiomind \
	--text="$label" \
	--window-icon=idiomind --align=right --center \
	--on-top --skip-taskbar \
	--width=400 --height=150 --borders=12 \
	--always-print-result --editable --print-all \
	--field="$(gettext "Automatically update feeds at startup")":chk "$act" \
	--button="$(gettext "Save")!gtk-apply":0 \
	--button="$(gettext "Close")":1)
	ret=$?

if [ $ret = 0 ]; then
    echo -e "update=\"$(cut -d "|" -f1 <<< "$c")\"" > "$fileconf"
fi

	exit 0
fi
