#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
DC_a="$HOME/.config/idiomind/addons"

name="$(gettext "Save as audio")"
header="<b>$name</b>"

# NOTE: yad --form/--info auto-grows its height with the --text length
# (long texts end up fullscreen tall with mostly empty space), and --height
# does not cap them. A --text-info view keeps a fixed compact height.
{
echo "$(gettext "Joins the audio of all sentences and words of the topic into a single MP3 album, so you can listen and practice outside Idiomind.")"
echo ""
echo "$(gettext "How pronunciation practice works")"
echo "$(gettext "After each item the exporter inserts preset cue/silence sounds to leave room for you to repeat aloud:")"
echo ""
echo "- $(gettext "Words:") audio [+ audio + si0_1.mp3 + audio, $(gettext "if repeating is on"))] + si1.mp3 + si4.mp3"
echo "- $(gettext "Sentences:") audio [+ audio + si0_2.mp3 + audio, $(gettext "if repeating is on"))] + si2.mp3 + si4.mp3"
echo ""
echo "  si1.mp3 ($(gettext "practice pause for words"))"
echo "  si2.mp3 ($(gettext "practice pause for sentences"))"
echo "  si4.mp3 ($(gettext "short separator between items"))"
echo "  si0_1.mp3 / si0_2.mp3 ($(gettext "pauses used when repetition is enabled"))"
echo ""
echo "$(gettext "To enable repetitions: Play > Options > Repeat sounding out > Words / Sentences.")"
echo ""
echo "$(gettext "The final MP3 also embeds the topic text as lyrics and a cover image for the learning language.")"
echo "$(gettext "Preset sounds are in:") $DS/addons/Save as audio/"
} | yad --text-info --title="$name" \
--name=Idiomind --class=Idiomind \
--text="$header" \
--window-icon=idiomind --center \
--on-top --skip-taskbar \
--wrap --width=560 --height=300 --borders=10 \
--button="$(gettext "Close")":1
ret=$?

exit 0
