#!/bin/bash
# -*- ENCODING: UTF-8 -*-

source "$DS/ifs/cmns.sh"
[ ! -e "$DC_a/gtts.cfg" ] && touch "$DC_a/gtts.cfg"
char_ini="$(grep -o ini=\"[^\"]* "$DC_a/gtts.cfg" |grep -o '[^"]*$')"
apikeygo="$(grep -o key=\"[^\"]* "$DC_a/gtts.cfg" |grep -o '[^"]*$')"
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

function audio_recog() {
    wget -q -U -T 51 -c "Mozilla/5.0" --post-file "${1}" \
    --header="Content-Type: audio/x-flac; rate=16000" \
    -O - "https://www.google.com/speech-api/v2/recognize?&lang=${2}-${3}&key=$4"
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

function dlg_file_2() {
    yad --file --save --title="$(gettext "Save")" \
    --name=Idiomind --class=Idiomind \
    --filename="$(date +%m-%d-%Y)"_audio.tar.gz \
    --window-icon=idiomind \
    --skip-taskbar --center --on-top \
    --width=600 --height=450 --borders=5 \
    --button="$(gettext "OK")":0
}

if [[ ${conten^} = ${char_ini^} ]]; then

    if [ -z "$apikeygo" ]; then
        msg "Key not found!" dialog-information
        cleanups "$lckpr" "$DT_r" & exit 1
    fi
    cd "$HOME"; fl="$(dlg_file_1)"
    if [ -z "${fl}" ];then
        cleanups "$DT_r" "$lckpr" & exit 1
    else
        internet
        check_s "${tpe}"
        notify-send -i idiomind "$(gettext "Getting text from audio files")" \
        "$(gettext "Wait a moment please...")"
        cd "$DT_r"
        
        if grep ".mp3" <<< "${fl: -4}"; then
            cp -f "${fl}" "$DT_r/rv.mp3"
            sox "$DT_r/rv.mp3" "$DT_r/c_rv.mp3" remix - highpass 100 norm \
            compand 0.05,0.2 6:-54,-90,-36,-36,-24,-24,0,-12 0 -90 0.1 \
            vad -T 0.6 -p 0.2 -t 5 fade 0.1 reverse \
            vad -T 0.6 -p 0.2 -t 5 fade 0.1 reverse norm -0.5
            rm -f "$DT_r/rv.mp3"
            mp3splt -s -o @n *.mp3
            if ls [0-9]*.mp3 1> /dev/null 2>&1; then
                c="$(ls [0-9]*.mp3 | wc -l)"
                if [[ ${c} -ge 1 ]]; then 
                    (rename 's/^0*//' *.mp3)
                fi
            elif [ $(du ./"c_rv.mp3" | cut -f1) -lt 400 ]; then
                mv -f ./"c_rv.mp3" ./"1.mp3"
            fi
            [ -f "$DT_r/c_rv.mp3" ] && rm -f "$DT_r/c_rv.mp3"
        elif grep ".tar" <<< "${fl: -4}"; then
            cp -f "$fl" "$DT_r/rv.tar"
            tar -xvf "$DT_r/rv.tar"
        elif grep ".tar.gz" <<< "${fl: -7}"; then
            cp -f "$fl" "$DT_r/rv.tar.gz"
            tar -xzvf "$DT_r/rv.tar.gz"
        fi

        echo "# $(gettext "Checking key")..."
        data="$(audio_recog "$_testflac" "$lgt" "$lgt" $apikeygo)"
        if [ -z "${data}" ]; then
            msg "The key is invalid or has exceeded its quota of daily requests" error
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
     
        ( echo "1"
        echo "# $(gettext "Processing... Wait.")";
        erw=1
        while [[ ${erw} -le ${lns} ]]; do
            [ ! -f "$DT/n_s_pr" ] && break
            unset trgt; unset _item
            if [ -f "$DT_r/${erw}.mp3" ]; then
                if [ ! -f "$DT_r/index" ]; then
                    sox "$DT_r/${erw}.mp3" "$DT_r/info.flac" rate 16k
                    data="$(audio_recog "$DT_r/info.flac" $lgt $lgt $apikeygo)"
                    if [ -z "${data}" ]; then
                        msg "The key is invalid or has exceeded its quota of daily requests\n" error
                        cleanups "$DT_r" "$lckpr"
                        "$DS/stop.sh" 5 & break & exit 1
                    fi
                    trgt="$(echo "${data}" |sed '1d' \
                    |sed 's/.*transcript":"//' \
                    |sed 's/"}],"final":true}],"result_index":0}//g' \
                    |sed 's/.*transcript":"//g' \
                    |sed 's/","confidence"://g' \
                    |sed "s/[0-9].[0-9]//g" \
                    |sed 's/}],"final":true}],"result_index":0}//g')"
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
            echo "# ${trgt:0:35}..." ;
            let erw++
        done
        ) | dlg_progress_2
        
        # ----
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
                        export DT_r; sentence_p 1
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
        if [ ${wadds} = 1 ]; then
            W=" $(gettext "word")"
        fi
        sadds=$(sed '/^$/d' "$DT_r/adds" |wc -l)
        S=" $(gettext "sentences")"
        if [ ${sadds} = 1 ]; then
            S=" $(gettext "sentence")"
        fi
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
