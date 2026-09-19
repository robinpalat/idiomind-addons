#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"

DC_a="$HOME/.config/idiomind/addons"
CFG="$DC_a/speech_to_text.cfg"
mkdir -p "$DC_a"

name="$(gettext "Speech to text")"
label="$(gettext "Configure the speech recognition provider used by Idiomind.")"

# Migrate the old Google configuration if it exists.
if [ ! -f "$CFG" ]; then
    old="$DC_a/gtts.cfg"
    old_ini=""
    old_key=""

    if [ -f "$old" ]; then
        old_ini="$(sed -n 's/.*ini="\([^"]*\).*/\1/p' "$old")"
        old_key="$(sed -n 's/.*key="\([^"]*\).*/\1/p' "$old")"
    fi

    cat > "$CFG" <<EOF
provider="google"
ini="${old_ini:-a}"
openai_api_key=""
openai_model="gpt-4o-mini-transcribe"
google_project=""
google_location="us"
google_model="chirp_3"
EOF
fi

cfg() {
    sed -n "s/^[[:space:]]*$1=\"\([^\"]*\)\"/\1/p" "$CFG" | head -n1
}

provider="$(cfg provider)"
ini="$(cfg ini)"
openai_api_key="$(cfg openai_api_key)"
openai_model="$(cfg openai_model)"
google_project="$(cfg google_project)"
google_location="$(cfg google_location)"
google_model="$(cfg google_model)"

: "${provider:=openai}"
: "${ini:=a}"
: "${openai_model:=gpt-4o-mini-transcribe}"
: "${google_location:=us}"
: "${google_model:=chirp_3}"

c="$(
    yad --form \
    --title="$name" \
    --name=Idiomind --class=Idiomind \
    --text="<b>$name</b>\n<small>$label</small>\n\n<small>$(gettext "You only need to configure one provider. If several providers are configured, only the selected provider will be used.")</small>" \
    --window-icon=idiomind --align=right --center \
    --on-top --skip-taskbar --expand-column=3 \
    --width=560 --height=500 --borders=15 \
    --always-print-result --editable --print-all \
    --field="<b>$(gettext "Provider")</b>:LBL" "" \
    --field="Provider:CB" "$provider!openai!google" \
    --field="<b>$(gettext "Invocation")</b>:LBL" "" \
    --field="$(gettext "Use this character to invoke:")" "$ini" \
    --field="\n:LBL" "" \
    --field="<b>OpenAI</b>:LBL" "" \
    --field="OpenAI API Key:H" "$openai_api_key" \
    --field="OpenAI Model:CB" "$openai_model!gpt-4o-mini-transcribe!gpt-4o-transcribe" \
    --field="<b>Google Cloud</b>:LBL" "" \
    --field="Google Cloud Project ID" "$google_project" \
    --field="Google Location:CB" "$google_location!us!eu" \
    --field="Google Model:CB" "$google_model!chirp_3!chirp_2!long" \
    --field="<small>OpenAI: https://platform.openai.com/api-keys\nGoogle Cloud: authenticate with gcloud.</small>\n\n:LBL" "" \
    --button="$(gettext "Save")!gtk-apply":0 \
    --button="$(gettext "Close")":1
)"
ret=$?

if [[ $ret = 0 ]]; then
    # YAD includes :LBL fields in the printed result. Extract only
    # the actual form controls, preserving their order.
    IFS='|' read -r provider _label1 ini _label2 openai_api_key openai_model \
        _label3 google_project google_location google_model _label4 <<< "$c"

    cat > "$CFG" <<EOF
provider="$provider"
ini="$ini"
" "
openai_api_key="$openai_api_key"
openai_model="$openai_model"
google_project="$google_project"
google_location="$google_location"
google_model="$google_model"
EOF
fi

exit 0
