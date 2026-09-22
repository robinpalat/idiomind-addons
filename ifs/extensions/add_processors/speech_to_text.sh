#!/bin/bash
# -*- ENCODING: UTF-8 -*-

# Speech to text - provider-neutral front end for Idiomind.
# Supported providers:
#   openai  -> OpenAI Audio Transcriptions API
#   google  -> Google Cloud Speech-to-Text V2
#
# The rest of Idiomind only sees the text returned by stt_transcribe().
# Adding another provider only requires another stt_<provider>() function.

source "$DS/ifs/cmns.sh"

CFG="$DC_a/speech_to_text.cfg"
[ ! -e "$CFG" ] && touch "$CFG"

stt_cfg() {
    sed -n "s/^[[:space:]]*$1=\"\([^\"]*\)\"/\1/p" "$CFG" | head -n1
}

STT_PROVIDER="$(stt_cfg provider)"
STT_CHAR="$(stt_cfg ini)"
OPENAI_KEY="$(stt_cfg openai_api_key)"
OPENAI_MODEL="$(stt_cfg openai_model)"
GOOGLE_PROJECT="$(stt_cfg google_project)"
GOOGLE_LOCATION="$(stt_cfg google_location)"
GOOGLE_MODEL="$(stt_cfg google_model)"

: "${STT_PROVIDER:=openai}"
: "${OPENAI_MODEL:=gpt-4o-mini-transcribe}"
: "${GOOGLE_LOCATION:=us}"
: "${GOOGLE_MODEL:=chirp_3}"

_testflac="$DS/addons/Speech to text/test.flac"

function dlg_progress_2() {
    yad --progress --title="$(gettext "Progress")" \
    --name=Idiomind --class=Idiomind \
    --window-icon=idiomind --align=right \
    --progress-text=" " --auto-close \
    --percentage="0" --timeout=300 \
    --no-buttons --on-top --fixed \
    --width=300 --height=40 --borders=4 --geometry=300x40-50-50
}

# Idiomind language code -> ISO-639-1 for OpenAI.
function openai_language() {
    case "$1" in
        zh-cn|zh-CN|zh) echo "zh" ;;
        pt-br|pt-BR|pt) echo "pt" ;;
        es-*|es_*) echo "es" ;;
        en-*|en_*) echo "en" ;;
        fr-*|fr_*) echo "fr" ;;
        de-*|de_*) echo "de" ;;
        it-*|it_*) echo "it" ;;
        ja-*|ja_*) echo "ja" ;;
        ko-*|ko_*) echo "ko" ;;
        ru-*|ru_*) echo "ru" ;;
        *) echo "$1" | cut -d- -f1 | cut -d_ -f1 ;;
    esac
}

# Extract the transcript from provider JSON.
# jq is preferred; Python 3 is the fallback.
function json_text() {
    local json="$1"
    local path="$2"

    if command -v jq >/dev/null 2>&1; then
        jq -r "$path // empty" <<< "$json"
    elif command -v python3 >/dev/null 2>&1; then
        JSON_INPUT="$json" JSON_PATH="$path" python3 - <<'PY'
import json, os

try:
    obj = json.loads(os.environ["JSON_INPUT"])
    path = os.environ["JSON_PATH"]

    if path == ".text":
        value = obj.get("text", "")
    elif path == ".results":
        value = " ".join(
            a.get("transcript", "")
            for r in obj.get("results", [])
            for a in r.get("alternatives", [])[:1]
        )
    else:
        value = ""

    print(value)
except Exception:
    pass
PY
    fi
}

function stt_openai() {
    local audio="$1"
    local lang="$2"
    local response http_code text

    [ -z "$OPENAI_KEY" ] && {
        echo "OpenAI API key not configured." >&2
        return 1
    }

    response="$(
        curl -sS \
            --connect-timeout 15 \
            --max-time 300 \
            -w $'\n%{http_code}' \
            -X POST "https://api.openai.com/v1/audio/transcriptions" \
            -H "Authorization: Bearer $OPENAI_KEY" \
            -F "file=@$audio" \
            -F "model=$OPENAI_MODEL" \
            -F "language=$(openai_language "$lang")"
    )" || {
        echo "Could not connect to OpenAI." >&2
        return 1
    }

    http_code="${response##*$'\n'}"
    response="${response%$'\n'*}"

    if [ "$http_code" != "200" ]; then
        echo "OpenAI HTTP $http_code: $response" >&2
        return 1
    fi

    text="$(json_text "$response" ".text")"

    [ -n "$text" ] || {
        echo "OpenAI returned no transcription." >&2
        return 1
    }

    printf '%s\n' "$text"
}

function google_access_token() {
    if ! command -v gcloud >/dev/null 2>&1; then
        echo "Google Cloud CLI (gcloud) is not installed." >&2
        return 1
    fi

    gcloud auth print-access-token 2>/dev/null
}

function stt_google() {
    local audio="$1"
    local lang="$2"
    local token response http_code text endpoint
    local tmp_json

    [ -z "$GOOGLE_PROJECT" ] && {
        echo "Google Cloud project ID not configured." >&2
        return 1
    }

    token="$(google_access_token)" || return 1
    [ -n "$token" ] || {
        echo "Google Cloud authentication is not configured." >&2
        return 1
    }

    case "$lang" in
        zh-cn) lang="zh-CN" ;;
        pt-br) lang="pt-BR" ;;
    esac

    tmp_json="$(mktemp)" || return 1

    {
        printf '{'
        printf '"config":{"auto_decoding_config":{},'
        printf '"language_codes":["%s"],' "$lang"
        printf '"model":"%s"},' "$GOOGLE_MODEL"
        printf '"content":"'
        base64 -w 0 "$audio"
        printf '"}'
    } > "$tmp_json"

    endpoint="https://${GOOGLE_LOCATION}-speech.googleapis.com/v2/projects/${GOOGLE_PROJECT}/locations/${GOOGLE_LOCATION}/recognizers/_:recognize"

    response="$(
        curl -sS \
            --connect-timeout 15 \
            --max-time 300 \
            -w $'\n%{http_code}' \
            -X POST "$endpoint" \
            -H "Authorization: Bearer $token" \
            -H "x-goog-user-project: $GOOGLE_PROJECT" \
            -H "Content-Type: application/json; charset=utf-8" \
            --data-binary "@$tmp_json"
    )"
    local curl_status=$?

    rm -f "$tmp_json"

    [ "$curl_status" = 0 ] || {
        echo "Could not connect to Google Cloud." >&2
        return 1
    }

    http_code="${response##*$'\n'}"
    response="${response%$'\n'*}"

    if [ "$http_code" != "200" ]; then
        echo "Google Cloud HTTP $http_code: $response" >&2
        return 1
    fi

    text="$(json_text "$response" ".results")"

    [ -n "$text" ] || {
        echo "Google Cloud returned no transcription." >&2
        return 1
    }

    printf '%s\n' "$text"
}

function stt_transcribe() {
    local audio="$1"
    local lang="$2"

    case "$STT_PROVIDER" in
        openai) stt_openai "$audio" "$lang" ;;
        google) stt_google "$audio" "$lang" ;;
        *)
            echo "Unsupported Speech-to-text provider: $STT_PROVIDER" >&2
            return 1
            ;;
    esac
}

function dlg_file_1() {
    yad --file --title="$(gettext "Select File")" \
    --text=" $(gettext "Browse to and select the audio file that you want to add.")" \
    --name=Idiomind --class=Idiomind \
    --file-filter="*.mp3 *.tar *.tar.gz" \
    --window-icon=idiomind \
    --skip-taskbar --on-top --center \
    --width=600 --height=450 --borders=5
}


if [[ -n "${conten}" && ${conten^} = ${STT_CHAR^} ]]; then

    case "$STT_PROVIDER" in
        openai)
            [ -z "$OPENAI_KEY" ] && {
                msg "OpenAI API key not configured!" dialog-information
                cleanups "$lckpr" "$DT_r" & exit 1
            }
            ;;
        google)
            [ -z "$GOOGLE_PROJECT" ] && {
                msg "Google Cloud project ID not configured!" dialog-information
                cleanups "$lckpr" "$DT_r" & exit 1
            }
            ;;
        *)
            msg "Speech-to-text provider is not configured!" error
            cleanups "$lckpr" "$DT_r" & exit 1
            ;;
    esac

    cd "$HOME"
    fl="$(dlg_file_1)"

    if [ -z "${fl}" ]; then
        cleanups "$DT_r" "$lckpr" & exit 1
    else
        internet
        check_s "${tpe}"
        notify-send -i idiomind "$(gettext "Getting text from audio files")" \
        "$(gettext "Wait a moment please...")"
        cd "$DT_r"

        case "$fl" in
            *.mp3)
                cp -f "$fl" "$DT_r/rv.mp3"
                sox "$DT_r/rv.mp3" "$DT_r/c_rv.mp3" remix - highpass 100 norm \
                compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
                vad -T 0.6 -p 0.2 -t 5 fade 0.1 reverse \
                vad -T 0.6 -p 0.2 -t 5 fade 0.1 reverse norm -0.5
                rm -f "$DT_r/rv.mp3"
                mp3splt -s -o @n *.mp3
                if ls [0-9]*.mp3 1> /dev/null 2>&1; then
                    c="$(ls [0-9]*.mp3 | wc -l)"
                    [ "$c" -ge 1 ] && (rename 's/^0*//' *.mp3)
                elif [ "$(du ./"c_rv.mp3" | cut -f1)" -lt 400 ]; then
                    mv -f "./c_rv.mp3" "./1.mp3"
                fi
                [ -f "$DT_r/c_rv.mp3" ] && rm -f "$DT_r/c_rv.mp3"
                ;;
            *.tar)
                cp -f "$fl" "$DT_r/rv.tar"
                tar -xvf "$DT_r/rv.tar"
                ;;
            *.tar.gz)
                cp -f "$fl" "$DT_r/rv.tar.gz"
                tar -xzvf "$DT_r/rv.tar.gz"
                ;;
        esac

        echo "# $(gettext "Checking provider")..."
        data="$(stt_transcribe "$_testflac" "$lgt")"

        if [ -z "${data}" ]; then
            msg "Speech-to-text provider could not transcribe the test audio." error
            cleanups "$DT_r" "$lckpr" & exit 1
        fi

        echo "# $(gettext "Processing")..."
        touch "$DT_r/wlog" "$DT_r/slog" \
        "$DT_r/adds" "$DT_r/addw" "$DT_r/swlog"

        if [ ! -d "${DM_tlt}" ]; then
            msg " $(gettext "An error occurred.")\n" dialog-warning
            cleanups "$DT_r" "$lckpr" "$slt" & exit 1
        fi

        internet
        if [ "$lgt" = ja -o "$lgt" = 'zh-cn' -o "$lgt" = ru ]; then c=c; else c=w; fi
        lns=$(ls "$DT_r"/[0-9]*.mp3 |wc -l |head -200)

        (
            echo "1"
            echo "# $(gettext "Processing... Wait.")"
            erw=1

            while [[ ${erw} -le ${lns} ]]; do
                [ ! -f "$DT/n_s_pr" ] && break
                unset trgt; unset _item

                if [ -f "$DT_r/${erw}.mp3" ]; then
                    if [ ! -f "$DT_r/index" ]; then
                        sox "$DT_r/${erw}.mp3" "$DT_r/info.flac" rate 16k
                        data="$(stt_transcribe "$DT_r/info.flac" "$lgt")"

                        if [ -z "${data}" ]; then
                            msg "The Speech-to-text provider returned no text.\n" error
                            cleanups "$DT_r" "$lckpr"
                            "$DS/stop.sh" 5 & break & exit 1
                        fi

                        trgt="$data"
                    else
                        trgt="$(sed -n ${erw}p "$DT_r/index" |sed 's/^\s*./\U&\E/g')"
                    fi

                    if [ -f "$DT_r/translation" ]; then
                        export srce="$(sed -n ${erw}p "$DT_r/translation" |sed 's/^\s*./\U&\E/g')"
                    else
                        export trgt=$(clean_2 "${trgt}")
                        srce="$(translate "${trgt}" $lgt $lgs |sed ':a;N;$!ba;s/\n/ /g')"
                        export srce="$(clean_2 "${srce}")"
                    fi

                    rm -f "$DT_r/info.flac" "$DT_r/info.ret"
                fi

                echo "${trgt}" >> "$DT_r/trgt"
                echo "${srce}" >> "$DT_r/srce"
                echo "$((100*erw/lns))"
                echo "# ${trgt:0:35}..."
                let erw++
            done
        ) | dlg_progress_2

        erw=1
        while [[ ${erw} -le ${lns} ]]; do
            [ ! -f "$DT/n_s_pr" ] && break
            unset trgt; unset _item
            trgt="$(sed -n ${erw}p "$DT_r/trgt")"
            srce="$(sed -n ${erw}p "$DT_r/srce")"

            if [ ${#trgt} -ge 400 ]; then
                echo -e "$(gettext "Sentence too long")\n$erw) $trgt\n\n" >> "$DT_r/slog"
            elif [ -z "$trgt" ]; then
                trgt="$erw) ..."
                export cdid="$(set_name_file 2 "${trgt}" "" "" "" "" "")"
                index 2
                mv -f "$DT_r/${erw}.mp3" "${DM_tlt}/$cdid.mp3"
                echo -e "$(gettext "Text missing:")\n$trgt\n\n" >> "$DT_r/slog"
            elif [[ $(wc -l < "${DC_tlt}/data") -ge 200 ]]; then
                echo -e "$(gettext "Maximum number of notes has been exceeded")\n$erw) $trgt\n\n" >> "$DT_r/slog"
            else
                if [ $(wc -${c} <<< "${trgt}") -eq 1 ]; then
                    export trgt="$(clean_1 "${trgt}")"
                    export srce="$(clean_1 "${srce}")"
                    export cdid="$(set_name_file 1 "${trgt}" "${srce}" "" "" "" "" "")"
                    audio="${trgt,,}"
                    mksure "${trgt}" "${srce}"

                    if [ $? = 0 ]; then
                        index 1
                        mv -f "$DT_r/${erw}.mp3" "${DM_tlt}/$cdid.mp3"
                        echo "${trgt}" >> "$DT_r/addw"
                    else
                        echo -e "$erw) $trgt\n\n" >> "$DT_r/wlog"
                    fi
                elif [ $(wc -${c} <<< "$trgt") -ge 1 ]; then
                    (
                        export DT_r
                        sentence_p 1
                        export cdid="$(set_name_file 2 "${trgt}" "${srce}" "" "" "${wrds}" "${grmr}")"
                        mksure "${trgt}" "${srce}" "${wrds}" "${grmr}"

                        if [ $? = 0 ]; then
                            index 2
                            mv -f "$DT_r/${erw}.mp3" "${DM_tlt}/$cdid.mp3"
                            echo "${trgt}" >> "$DT_r/adds"
                            ( fetch_audio "$aw" "$bw" )
                        else
                            echo -e "$erw) $trgt" >> "$DT_r/slog"
                        fi

                        rm -f "$aw" "$bw"
                    )
                fi
            fi

            let erw++
        done

        wadds=$(sed '/^$/d' "$DT_r/addw" |wc -l)
        W=" $(gettext "words")"
        [ "$wadds" = 1 ] && W=" $(gettext "word")"

        sadds=$(sed '/^$/d' "$DT_r/adds" |wc -l)
        S=" $(gettext "sentences")"
        [ "$sadds" = 1 ] && S=" $(gettext "sentence")"

        _log=$(cat "$DT_r/slog" "$DT_r/wlog")
        adds=$(cat "$DT_r/adds" "$DT_r/addw" |sed '/^$/d' |wc -l)

        if [ ${adds} -ge 1 ]; then
            notify-send -i idiomind "$tpe" \
            "$(gettext "Have been added:")\n$sadds$S$wadds$W" -t 2000 &
        fi

        [ -n "$_log" ] && echo "$_log" >> "${DC_tlt}/note.inf"
        cleanups "$DT_r" "$DT/n_s_pr"
    fi
    exit 0
fi
