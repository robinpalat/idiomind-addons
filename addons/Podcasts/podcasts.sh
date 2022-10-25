#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf

sz=(530 560 300); [[ ${swind} = TRUE ]] && sz=(450 460 300)

f="$(gettext "Favorites<i><small><small> Podcasts</small></small></i>")"
c="$(gettext "Videos<i><small><small> Podcasts</small></small></i>")"
b="$(gettext "New episodes<i><small><small> Podcasts</small></small></i>")"
CNF="$(gettext "Configure")"
source "$DS/ifs/cmns.sh"
DMC="$DM_tl/Podcasts/cache"
DMP="$DM_tl/Podcasts"
DSP="$DS_a/Podcasts"
dfimg="$DSP/images/audio.png"
updt="$DT/updating_podcasts"
date=$(date +%d)
DCP="$DM_tl/Podcasts/.conf"
downloads=2
rsync_delete=0
eyed3_encoding=utf8

function dlg_progress() {
    yad --progress --title="Idiomind" \
    --text="<b>$1</b>" \
    --name=Idiomind --class=Idiomind \
    --window-icon=idiomind --align=right \
    --progress-text=" " --pulsate  \
    --percentage="0" --auto-close \
    --no-buttons --on-top --fixed \
    --width=420 --borders=10
}

function dlg_optns() {
    cfg=0
    if [ -e "$DCP/podcasts.cfg" ]; then
        [[ $(egrep -cv '#|^$' < "$DCP/podcasts.cfg") = 8 ]] && cfg=1
    else 
        > "$DCP/podcasts.cfg"
    fi
    sets=( 'update' 'sync' 'synf' 'path' 'eaudio' 'evideo' 'ekeep' 'altrvi' )
    if [ ! -d "${path}" -o ! -n "${path}" ]; then path=/FALSE; fi
    n=0
    if [ ${cfg} = 1 ]; then
        while [ ${n} -le 7 ]; do
            get="${sets[${n}]}"
            val=$(grep -o "$get"=\"[^\"]* "$DCP/podcasts.cfg" |grep -o '[^"]*$')
            declare ${sets[${n}]}="$val"
            ((n=n+1))
        done
    else
        > "$DCP/podcasts.cfg"
        while [ ${n} -le 7 ]; do
            echo -e "${sets[${n}]}=\"FALSE\"" >> "$DCP/podcasts.cfg"
            ((n=n+1))
        done
        sed -i "s/altrvi=\"FALSE\"/altrvi=\"\"/g" "$DCP/podcasts.cfg"
    fi

    ( 
    if [ -n "$altrvi" ]; then
        if ! which "$altrvi" >/dev/null; then
            sleep 2
            msg "$(gettext "The specified path for the video player does not exist")" info
        fi
    fi
    ) &
    
    CNFG="$(yad --form --title="$(gettext "Options")" \
    --name=Idiomind --class=Idiomind \
    --always-print-result --print-all --separator="|" \
    --window-icon=$DS/images/logo.png \
    --scroll --mouse \
    --width=350 --height=360 --borders=8 \
    --field="$(gettext "Checks for new episodes at startup")":CHK "$update" \
    --field=" ":LBL " " \
    --field="$(gettext "Use this video player")":LBL " " \
    --field="" "$altrvi" \
    --field=" ":LBL " " \
    --field="$(gettext "Sync after update")":CHK "$sync" \
    --field="$(gettext "Sync only favorites")":CHK "$synf" \
    --field="$(gettext "Path where episodes should be synced")":LBL " " \
    --field="":DIR "$path" \
    --field="$(gettext "Synchronize")":FBTN "$DSP/podcasts.sh 'sync' 2" \
    --button="$(gettext "Save")"!gtk-apply:0 \
    --button="$(gettext "Close")":1)"
    ret=$?
    if [ $ret -eq 0 ]; then
        val1=$(cut -d "|" -f1 <<< "$CNFG")
        val2=$(cut -d "|" -f4 <<< "$CNFG")
        val3=$(cut -d "|" -f6 <<< "$CNFG")
        val4=$(cut -d "|" -f7 <<< "$CNFG" |sed 's|/|\\/|g')
        val5=$(cut -d "|" -f9 <<< "$CNFG" |sed 's|/|\\/|g')
        if [ ! -d "$val5" -o -z "$val5" ]; then path=FALSE; fi
        sed -i "s/update=.*/update=\"${val1}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/altrvi=.*/altrvi=\"${val2}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/sync=.*/sync=\"${val3}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/synf=.*/synf=\"${val4}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/path=.*/path=\"${val5}\"/g" "$DCP/podcasts.cfg"
    fi
}

function dlg_links() {

    checkpods() {
        touch "$DT/Sclk"
        ( cleanups "$DCP/downloaded" "$DT/Podcasts.lst"; cd "$DT"
        wget -T 10 "https://idiomind.sourceforge.io/share/${tlng}/Podcasts.lst"
        
        if [ -f "$DT/Podcasts.lst" ]; then
            if cat "$DT/Podcasts.lst" |grep -o 'SEL|'; then
                mkdir "$DCP/downloaded"
                mv -f  "$DT/Podcasts.lst" "$DCP/downloaded/Podcasts.lst"
                n="$(cat "$DCP/downloaded/Podcasts.lst" | wc -l)"
                cd "$DCP/downloaded"
                 echo "1"; echo "#  "
                i=1; while [ ${i} -le ${n} ]; do
                    wget -T 20 "https://idiomind.sourceforge.io/share/${tlng}/Podthumbs/$i.jpg"
                    if [ ! -f "$DCP/downloaded/$i.jpg" ]; then
                        cp "$DS/addons/Podcasts/images/def.jpg" "$DCP/downloaded/$i.jpg"
                    fi
                    echo $i
                    let i++
                done
            fi
            cd /
        fi
        echo '100'
         ) | dlg_progress "<b>$(gettext "Downloading list ...")</b>"
        
        cleanups "$DT/Sclk" "$DT/Podcasts.lst"
    }
    
    if [ -f "$DT/Sclk" ]; then
        msg "$(gettext "Please wait until the current process is finished")...\n" dialog-information
        (sleep 50; cleanups "$DT/Sclk") & exit 1
    fi
    
    if [ -f "$DCP/downloaded/Podcasts.lst" ]; then
        lstFile="$DCP/downloaded/Podcasts.lst"
    else
        checkpods
        lstFile="$DCP/downloaded/Podcasts.lst"
    fi
        
    function _list() {

        d="$DCP/downloaded"
        n=7; i=1; while read -r line; do
            if echo "${line}" |grep -o 'SEL|' >/dev/null 2>&1; then
                [ ! -s "$DCP/${n}.rss" ] && cleanups "$DCP/${n}.rss"
                [ -f "$DCP/${n}.rss" ] && val=TRUE || val=FALSE
                echo -e "$d/$i.jpg|${line}" |sed "s/SEL/${val}/g" |tr -s '|' '\n'
                let n++ i++
            fi
        done < "${lstFile}"
    }
    dlg="$(_list |yad --list \
    --title="$(gettext "Suggested podcasts to learn") $tlng" \
    --name=Idiomind --class=Idiomind  \
    --print-all --print-column=3 \
    --always-print-result --separator="|" \
    --window-icon=$DS/images/logo.png \
    --expand-column=0 --hide-column=3 \
    --center --no-headers \
    --width=520 --height=390 --borders=8 \
    --column="":IMG \
    --column="":CHK \
    --column="":TEXT \
    --column="":TEXT \
    --column="":TEXT \
    --button="$(gettext "Update List")":2 \
    --button="$(gettext "Save")!gtk-apply":0 \
    --button="$(gettext "Close")":1)"
    ret=$?
    if [ ${ret} = 0 ]; then
        touch "$DT/Sclk"
        n=7; echo "${dlg}" |while read -r sel; do
            if echo "${sel}" |grep -q 'TRUE'; then
                lnk="$(cut -f3 -d'|' <<< "${sel}")"
                if [ ! -f "$DCP/${n}.rss" ]; then
                    "$DSP/podcasts.sh" set_channel "${lnk}" ${n}
                fi
            else
                cleanups "$DCP/${n}.rss"
            fi
        n=$((n+1)); [ ${n} -gt 20 ] && break
        done
    elif [ ${ret} = 2 ]; then

        checkpods
        "$DSP/podcasts.sh" dlg_links & return

    fi
    cleanups "$DT/Sclk"
}

function dlg_subs() {
   
    [ -e "$DT/cp.lock" ] && kill $(cat "$DT/cp.lock")
    echo $$ > "$DT/cp.lock"
    touch "$DM_tl/Podcasts"
    check_file "$DCP/feeds.lst"
    n=1
    while read -r feed; do
        declare url${n}="$feed"
        ((n=n+1))
    done < "$DCP/feeds.lst"

    apply() {
        echo -e "${CNFG}" |sed 's/|/\n/g' |sed -n 2,8p | \
        sed 's/^ *//; s/ *$//g' |sed '/^$/d' >> "$DT/podcasts.tmp"
        n=1
        while read -r feed; do
            declare mod${n}="${feed}"
            mod="mod${n}"; url="url${n}"
            if [ ! -e "$DCP/${n}.rss" -a -n "${!mod}" ]; then
                echo "  -- set channel (noconfig) ${!mod} ${n}"
                "$DSP/podcasts.sh" set_channel "${!mod}" ${n} &
            elif [ "${!url}" != "${!mod}" ]; then
                echo "  -- set channel (mod) ${!mod} ${n}"
                "$DSP/podcasts.sh" set_channel "${!mod}" ${n} &
            elif [ ! -s "$DCP/${n}.rss" -a -n "${!mod}" ]; then
                echo "  -- set channel (noconfig) ${!mod} ${n}"
                "$DSP/podcasts.sh" set_channel "${!mod}" ${n} & fi
            ((n=n+1))
        done < "$DT/podcasts.tmp"
        
        podcasts_tmp="$(cat "$DT/podcasts.tmp")"
        if [[ "$podcasts_tmp" != "$(cat "$DCP/feeds.lst")" ]]; then
        mv -f "$DT/podcasts.tmp" "$DCP/feeds.lst"; else rm -f "$DT/podcasts.tmp"; fi
        cleanups "$DT/cp.lock"
    }
    if [ -f "$DM_tl/Podcasts/.conf/feed.err" ]; then
    e="$(head -n 4 < "$DM_tl/Podcasts/.conf/feed.err" |sed 's/\&/\&amp\;/g' |awk '!a[$0]++')"
    rm "$DM_tl/Podcasts/.conf/feed.err"
    ( sleep 2 && msg "$e\n\t" dialog-information "$(gettext "Errors found")" ) &
    fi
        
    LANGUAGE_TO_LEARN="$(gettext ${tlng})"
    CNFG="$(yad --form --title="$(gettext "Subscriptions")" \
    --name=Idiomind --class=Idiomind \
    --always-print-result --print-all --separator="|" \
    --window-icon=$DS/images/logo.png \
    --scroll --mouse \
    --width=450 --height=340 --borders=8 \
    --field="$(gettext "Add URL of podcasts about languages")":LBL " " \
    --field="" "${url1}" --field="" "${url2}" --field="" "${url3}" \
    --field="" "${url4}" --field="" "${url5}" --field="" "${url6}" \
    --field="$(gettext "Suggested Podcasts")":FBTN "$DSP/podcasts.sh 'dlg_links'" \
    --button="$(gettext "Save")"!gtk-apply:0 \
    --button="$(gettext "Close")":1)"
    ret=$?
    if [ $ret -eq 0 ]; then apply; fi
    cleanups "$DT/cp.lock"
    return
}

function podmode() {
    
    nmfile() { echo -n "${1}" |md5sum |rev |cut -c 4- |rev; }
    function _list_1() {
        while read -r list1; do
            if [ -f "$DMP/cache/$(nmfile "$list1").png" ]; then
                echo "$DMP/cache/$(nmfile "$list1").png"
            else 
                echo "$DS_a/Podcasts/images/audio.png"; fi
            echo "$list1"
        done < "$DCP/1.lst"
    }
    function _list_2() {
        while read -r list2; do
            if [ -f "$DMP/cache/$(nmfile "$list2").png" ]; then
                echo "$DMP/cache/$(nmfile "$list2").png"
            else
            echo "$DS_a/Podcasts/images/audio.png"; fi
            echo "$list2"
        done < "$DCP/2.lst"
    }

    c=$(echo $(($RANDOM%100000))); KEY=$c
    if [ -d "$DT"/*.dl_poddir ]; then
        info="$(gettext "Downloading...")\n"
    elif [ -e ${updt} ]; then
        info="$(gettext "Updating...")\n"
    else
        info=""
    fi
    cmd_sub="$DSP/cnfg.sh 'subs'"
    cmd_optns="$DSP/cnfg.sh 'optns'"
    cmd_del="$DSP/cnfg.sh 'delete_all'"
    infolabel="$(< "$DMP"/*.updt)"
    _list_1 |yad --list --tabnum=1 \
    --plug=$KEY --print-all \
    --dclick-action="$DSP/cnfg.sh viewer" \
    --no-headers --expand-column=2 \
    --ellipsize=end --wrap-width=${sz[2]} --ellipsize-cols=1 \
    --column=Name:IMG \
    --column=Name:TXT &
    yad --form --tabnum=2 \
    --plug=$KEY \
    --borders=10 --columns=2 \
    --field="<small><b>$info</b></small>$infolabel":LBL " " \
    --field=" ":LBL " " \
    --field=" ":LBL " " \
    --field=" $(gettext "Subscriptions") ":FBTN "$cmd_sub" \
    --field="$(gettext "Options")":FBTN "$cmd_optns" \
    --field="$(gettext "Remove")":FBTN "$cmd_del"  &
    yad --notebook --title="Idiomind - $(gettext "Podcasts")" \
    --name=Idiomind --class=Idiomind --key=$KEY \
    --always-print-result \
    --window-icon=$DS/images/logo.png --image-on-top \
    --ellipsize=END --align=right --center \
    --width=${sz[0]} --height=${sz[1]} \
    --borders=5 --tab-borders=0 \
    --tab=" $(gettext "Episodes") " \
    --tab=" $(gettext "Manage") " \
    --button="$(gettext "Play")":"$DS/play.sh play_list" \
    --button="$(gettext "Update")":2 \
    --button="$(gettext "Close")"!'window-close':1
    ret=$?
    if [ $ret -eq 2 ]; then "$DSP/podcasts.sh" update 1; fi

} 

function update() {
    include "$DS/ifs/mods/add"
    sets=( 'channel' 'link' 'logo' 'ntype' \
    'nmedia' 'ntitle' 'nsumm' 'nimage' 'url' )
    
    export fav_list="$(wc -l < "$DCP/.2.lst")"

    conditions() {
        if ps -A |pgrep -f "podcasts.sh set_channel"; then
            for s in {1..60}; do
                if ps -A |pgrep -f "podcasts.sh set_channel"; then
                    sleep 1; else break; fi
            done
        fi
        check_file "$DCP/1.lst" "$DCP/2.lst" "$DCP/.1.lst" "$DCP/.2.lst"

        if [ -e "$updt" ] && [[ ${1} = 1 ]]; then
            msg_4 "$(gettext "Wait until it finishes a previous process")." \
            "$DS/images/warning.png" OK "$(gettext "Stop")" "$(gettext "Information")"
            ret=$?
            if [ $ret -eq 1 ]; then
                sed -i "/$(gettext "Downloading")/d" "$DM_tl/Podcasts/$date.updt"
                cleanups "$updt"
                find "$DT_r" -maxdepth 1 -type d -name '*.dl_poddir' -exec rm -fr {} \;
                "$DS/addons/Podcasts/cnfg.sh" stop
            fi
            exit 1
        elif [ -e "$updt" ] && [[ ${1} = 0 ]]; then
            exit 1
        fi
        if [ -e "$DCP/2.lst" ] && [[ $(wc -l < "$DCP/2.lst") \
        != $(wc -l < "$DCP/.2.lst") ]]; then
            cp "$DCP/.2.lst" "$DCP/2.lst"
        fi
        if [ ! -f "$DC_a/Podcasts_tasks.cfg" ]; then
            echo "fixed=\"TRUE\"" > "$DC_a/Podcasts_tasks.cfg"
        fi
        cleanups "$DCP/read.tsk" "$DCP/watch.tsk" "$DCP/listen.tsk"
        if [ -e "$DCP/1.lst" ] && [[ $(wc -l < "$DCP/1.lst") \
        != $(wc -l < "$DCP/.1.lst") ]]; then
            cp "$DCP/.1.lst" "$DCP/1.lst"
        fi
        if [[ "$(< "$DCP/stts")" != 11 ]]; then
            echo 11 > "$DCP/stts"
        fi
        check_dir "$DM_tl/Podcasts/cache" "$DM_tl/Podcasts/.conf"
        check_file "$DCP/old.lst"

        if [[ ${1} = 1 ]]; then internet; else curl -v www.google.com 2>&1 \
        | grep -m1 "HTTP/1.1" >/dev/null 2>&1 || exit 1; fi
    }

    mediatype() {
        ex=0
        if echo "$1" |grep -q ".mp3"; then ex=mp3; tp=aud
        elif echo "$1" |grep -q ".mp4"; then ex=mp4; tp=vid
        elif echo "$1" |grep -q ".ogg"; then ex=ogg; tp=aud
        elif echo "$1" |grep -q ".m4v"; then ex=m4v; tp=vid
        elif echo "$1" |grep -q ".m4a"; then ex=m4a; tp=vid
        elif echo "$1" |grep -q ".mov"; then ex=mov; tp=vid
        elif echo "$1" |grep -o ".pdf"; then ex=pdf; tp=txt
        elif echo "${1,,}" |grep -q ".jpg"; then ex=jpg
        elif echo "${1,,}" |grep -o ".png"; then ex=png
        elif echo "${1,,}" |grep -q ".jpeg"; then ex=jpeg
        elif echo "${1,,}" |grep -o ".gif"; then ex=gif
        export ex tp
        else
        echo -e "$(gettext "Could not add some podcasts:")\n$FEED" >> "$DM_tl/Podcasts/.conf/feed.err"
        return; fi
    }

    mkhtml() {
        itm="$DMC/$fname.html"
        video="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/mkhtml.css\">
        \r<video controls>
        \r<source src=\"$fname.$ex\" type=\"video/mp4\">
        \rYour browser does not support the video tag.</video>"
        audio="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/mkhtml.css\">
        \r<br><div class=\"title\"><h2><a href=\"$link\">$title</a></h2></div><br>
        \r<div class=\"summary\"><audio controls><br>
        \r<source src=\"$fname.$ex\" type=\"audio/mpeg\">
        \rYour browser does not support the audio tag.</audio><br><br>
        \r$summary<br><br></div>"
        text1="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/mkhtml.css\">
        \r<body><br><br><div class=\"txttle\"><h2><b><a href=\"$link\">$title</a></b></h2></div><br>
        \r<div class=\"txtsum\"><div class=\"image\">
        \r<img src=\"img${fname}.${ex}\" alt=\"Image\" style=\"width:650px\"></div><br>
        \r$summary</div><br><br><div class=\"txttradsum\"><b>$titlesrce</b><br><br>$sumarysrce<br><br></div>
        \r</body>"
        text2="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/mkhtml.css\">
        \r<body><br><br><div class=\"txttle\"><h2><b><a href=\"$link\">$title</a></b></h2></div><br>
        \r<div class=\"txtsum\">
        \r$summary</div><br><br><div class=\"txttradsum\"><b>$titlesrce</b><br><br>$sumarysrce<br><br></div>
        \r</body>"
        if [[ ${tp} = vid ]]; then
            if [ $ex = m4v -o $ex = mp4 -o $ex = m4a ]; then t=mp4
            elif [ $ex = avi ]; then t=avi; fi
            echo -e "${video}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$itm"
        elif [[ ${tp} = aud ]]; then
            echo -e "${audio}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$itm"
        elif [[ ${tp} = txt_img ]]; then
            echo -e "${text1}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$itm"
        elif [[ ${tp} = txt ]]; then
            echo -e "${text2}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$itm"
        fi
    }

    get_images() {
        if [ "$tp" = 'aud' ]; then
            cp -f "$DSP/images/audio.png" "$DMC/$fname.png"
        elif [ "$tp" = 'vid' ]; then
            cp -f "$DSP/images/video.png" "$DMC/$fname.png"
        elif [ "$tp" = 'txt_img' -o "$tp" = 'txt' ]; then
            cp -f "$DSP/images/text.png" "$DMC/$fname.png"
        fi
    }
    
    fetch_podcasts() {
        n=0; d=0; tit=0; ait=0; vit=0
        include "$DS/ifs/mods/add"
        source "$DS/default/sets.cfg"
        lgt=${tlangs[$tlng]}
        lgs=${slangs[$slng]}
        for ln in {1..20}; do
            if [ -f "$DCP/${ln}.rss" ]; then
            FEED=$(grep -o "url"=\"[^\"]* "$DCP/${ln}.rss" |grep -o '[^"]*$')
            else continue; fi
            if [ ! -z "$FEED" ]; then
                echo -e "\n  -- updating $FEED\n"
                if [ ! -e "$DCP/${ln}.rss" ]; then
                    echo -e "  -- no config file! feed=${ln} $FEED\n"
                    echo -e "$(gettext "Please, reconfigure this feed:")\n$FEED" >> "$DCP/feed.err"
                else
                    unset channel link logo ntype nmedia ntitle nsumm nimage url taskItem
                    for get in "${sets[@]}"; do
                        val=$(grep -o "$get"=\"[^\"]* "$DCP/${ln}.rss" |grep -o '[^"]*$')
                        declare $get="$val"
                    done
                    if [ -z "${nmedia}" -a "${ntype}" = 1 ]; then
                        echo -e "  -- no-media! $FEED\n"
                        > "$DCP/${ln}.rss"
                        echo -e "$(gettext "Please, reconfigure this feed:")\n$FEED" >> "$DCP/feed.err"
                        continue
                    fi
                    if [ "$ntype" = 1 ]; then
                        curl -s "${FEED}" > "$DT/out.xml"
                        if grep '^$' "$DT/out.xml"; then
                            sed -i '/^$/d' "$DT/out.xml"
                        fi
                        podcast_items="$(xsltproc "$DS/default/tp1.xml" "$DT/out.xml")"
                        podcast_items="$(echo -e "${podcast_items}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
                        podcast_items="$(echo "${podcast_items}" | tr '\n' ' ' \
                        | tr -s '[:space:]' | sed 's/EOL/\n/g' | head -n ${downloads})"
                        podcast_items="$(echo "${podcast_items}" | sed '/^$/d')"
                        
                        while read -r item; do
                            fields="$(sed -r 's|-\!-|\n|g' <<< "${item}")"
                            enclosure=$(sed -n ${nmedia}p <<< "${fields}")
                            title=$(echo "${fields}" | sed -n ${ntitle}p | sed 's/\://g' \
                            | sed 's/\&quot;/\"/g' | sed "s/\&#39;/\'/g" \
                            | sed 's/\&/and/g' | sed 's/^\s*./\U&\E/g' \
                            | sed 's/<[^>]*>//g' | sed 's/^ *//; s/ *$//; /^$/d')
                            summary=$(echo "${fields}" | sed -n ${nsumm}p)
                            fname="$(nmfile "${title}")"
                            
                            if [[ ${#title} -ge 300 ]] || [ -z "${title}" ]; then
                                continue
                            fi
                            if ! grep -Fxo "${title}" < <(cat "$DCP/1.lst" "$DCP/2.lst" "$DCP/old.lst"); then
                                enclosure_url=$(curl -sILw %"{url_effective}" --url "$enclosure" |tail -n 1)
                                mediatype "$enclosure_url"
                                if [ ! -d "$DMC" ]; then
                                    break; exit 1
                                fi
                                if [ ! -d "$DT_r" ]; then
                                    export DT_r="$(mktemp -d "$DT/XXXXXX.dl_poddir")"; cd "$DT_r"
                                fi
                                cd "$DT_r"
                                if [ ! -e "$DMC/$fname.$ex" ]; then
                                    wget -q -c -T 51 -O ./"media.$ex" "$enclosure_url"
                                else 
                                    mv -f "$DMC/$fname.$ex" ./"media.$ex"
                                fi
                                e=$?
                                if [ $e = 0 ]; then
                                    get_images
                                    mv -f ./"media.$ex" "$DMC/$fname.$ex"
                                    eyeD3 --encoding=$eyed3_encoding -t "${title}" \
                                    -a "${channel}" -A "Podcasts" "$DMC/$fname.$ex"
                                    
                                    if [ -z "$link" ]; then
                                        link="http://idiomind.sourceforge.io/maintenance.html"
                                        export link
                                    fi
                                    
                                    mkhtml
                                    if [[ -s "$DCP/1.lst" ]]; then
                                        sed -i -e "1i${title}\\" "$DCP/1.lst"
                                    else 
                                        echo "${title}" > "$DCP/1.lst"
                                    fi
                                    
                                    taskItem="$(sed 's/\$/\\$/g' <<< "$title")"

                                    if [ $tp = aud ]; then 
                                        echo -e "${taskItem}" >> "$DCP/listen.tsk"
                                        let ait++
                                    fi
                                    if [ $tp = vid ]; then 
                                        echo -e "${taskItem}" >> "$DCP/watch.tsk"
                                        let vit++
                                    fi

                                    if grep '^$' "$DCP/1.lst"; then
                                        sed -i '/^$/d' "$DCP/1.lst"
                                    fi
                                    echo "${title}" >> "$DCP/.1.lst"
                                    echo "${title}" >> "$DT_r/log"
                                    echo -e "channel=\"${channel}\"
                                    \rlink=\"${link}\"
                                    \rtitle=\"${title}\"" \
                                    |sed -e 's/^[ \t]*//' \
                                    |tr -d '\n' > "$DMC/$fname.item"
                                    let d++
                                    echo -e "$(gettext "New Episodes:") $d" \
                                    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Podcasts/$date.updt"
                                fi
                            fi
                        done <<< "${podcast_items}"
                        
                    elif [ "$ntype" = 2 ]; then
                        curl -s "${FEED}" > "$DT/out.xml"
                        if grep '^$' "$DT/out.xml"; then
                            sed -i '/^$/d' "$DT/out.xml"
                        fi
                        podcast_items="$(xsltproc "$DS/default/tp2.xml" "$DT/out.xml")"
                        podcast_items="$(echo -e "${podcast_items}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
                        podcast_items="$(echo "${podcast_items}" | tr '\n' ' ' \
                        | tr -s '[:space:]' | sed 's/EOL/\n/g' | head -n ${downloads})"
                        podcast_items="$(echo "${podcast_items}" | sed '/^$/d')"

                        while read -r item; do
                            fields="$(sed -r 's|-\!-|\n|g' <<< "${item}")"
                            if [[ -n ${nimage} ]]; then
                                image=$(sed -n ${nimage}p <<< "${fields}")
                            else
                                image=0
                            fi
                            title=$(echo "${fields}" | sed -n ${ntitle}p | sed 's/\://g' \
                            | sed 's/\&quot;/\"/g' | sed "s/\&#39;/\'/g" \
                            | sed 's/\&/and/g' | sed 's/^\s*./\U&\E/g' \
                            | sed 's/<[^>]*>//g' | sed 's/^ *//; s/ *$//; /^$/d')
                            summary=$(echo "${fields}" | sed -n ${nsumm}p)
                            fname="$(nmfile "${title}")"
                            
                            if [[ ${#title} -ge 300 ]] || [ -z "${title}" ]; then
                                continue
                            fi
                            if ! grep -Fxo "${title}" < <(cat "$DCP/1.lst" "$DCP/2.lst" "$DCP/old.lst"); then

                                s="$(sed 's/<[^>]*>//g' <<< "${summary}")"
                                sumarysrce="$(translate "${s}" auto $lgs)"
                                titlesrce="$(translate "${title}" auto $lgs)"

                                if [ ! -d "$DMC" ]; then break; exit 1; fi
                                
                                if [ ! -d "$DT_r" ]; then
                                    export DT_r="$(mktemp -d "$DT/XXXXXX.dl_poddir")"; cd "$DT_r"
                                fi
                                cd "$DT_r"
                                if echo "$image" |grep -q "http" && [[ ${image} != 0 ]]; then
                                    enclosure_url=$(curl -sILw %"{url_effective}" --url "$image" |tail -n 1)
                                    mediatype "$enclosure_url"
                                    wget -q -c -T 51 -O ./"image.$ex" "$enclosure_url"
                                fi
             
                                if [ -f ./"image.$ex" ]; then
                                    if file ./"image.$ex" |grep -oE '\image|\bitmap|'; then
                                        tp=txt_img
                                        cp -f ./"image.$ex" "$DMC/img${fname}.$ex"
                                    else
                                        cleanups ./"image.$ex"
                                        tp=txt
                                    fi
                                else
                                    tp=txt
                                fi
                                
                                export tp
                                get_images
                                if [ -z "$link" ]; then
                                    link="http://idiomind.sourceforge.io/maintenance.html"
                                    export link
                                fi
                                mkhtml
                                
                                if [[ -s "$DCP/1.lst" ]]; then
                                    sed -i -e "1i${title}\\" "$DCP/1.lst"
                                else 
                                    echo "${title}" > "$DCP/1.lst"
                                fi

                                let tit++
                                taskItem="$(sed 's/\$/\\$/g' <<< "$title")"
                                echo -e "${taskItem}" >> "$DCP/read.tsk"

                                if grep '^$' "$DCP/1.lst"; then
                                    sed -i '/^$/d' "$DCP/1.lst"
                                fi
                                echo "${title}" >> "$DCP/.1.lst"
                                echo "${title}" >> "$DT_r/log"
                                echo -e "channel=\"${channel}\"
                                \rlink=\"${link}\"
                                \rtitle=\"${title}\"" \
                                |sed -e 's/^[ \t]*//' \
                                |tr -d '\n' > "$DMC/$fname.item"
                                let d++
                                echo -e "$(gettext "Latest downloads:") $d" \
                                |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Podcasts/$date.updt"
                               
                            fi
                        done <<< "${podcast_items}"
                    fi
                fi
            else
                cleanups "$DCP/${ln}.rss"
            fi
            let n++
        done
    }

    removes() {
        set -e
        check_index1 "$DCP/1.lst"
        tail -n +51 < "$DCP/1.lst" |sed '/^$/d' >> "$DCP/old.lst"
        head -n 50 < "$DCP/1.lst" |sed '/^$/d' > "$DCP/kept"
        cd "$DMC"/
        while read item; do
            if ! grep -Fxq "$item" < <(cat "$DCP/2.lst" "$DCP/kept"); then
                fname=$(nmfile "$item")
                if [ -n "$fname" ]; then
                    find . -maxdepth 1 -type f -name "$fname.*" -exec rm {} +
                fi
            fi
        done < "$DCP/old.lst"
        cd /
        while read k_item; do
            nmfile "${k_item}" >> "$DT/nmfile"
        done < <(cat "$DCP/1.lst" "$DCP/2.lst")
        while read r_item; do
            r_file=$(basename "$r_item" |sed "s/\(.*\).\{4\}/\1/" |tr -d '.')
            if ! grep -Fxq "${r_file}" < "$DT/nmfile"; then
                cleanups "$DMC/$r_item"
            fi
        done < <(find "$DMC" -type f)
        while read item; do
            fname="$(nmfile "${item}")"
            [ ! -e "$DMC/$fname.png" ] && cp "$dfimg" "$DMC/$fname.png"
            if [ -e "$DMC/$fname.html" -a -e "$DMC/$fname.item" ]; then
                continue
            else
                rm_item 2
            fi
        done < <(cat "$DCP/2.lst" "$DCP/kept")
        mv -f "$DCP/kept" "$DCP/1.lst"
        check_index1 "$DCP/1.lst" "$DCP/2.lst"
        if grep '^$' "$DCP/1.lst"; then
            sed -i '/^$/d' "$DCP/1.lst"
        fi
        if grep '^$' "$DCP/2.lst"; then
            sed -i '/^$/d' "$DCP/2.lst"
        fi
        head -n 500 < "$DCP/old.lst" > "$DCP/old_.lst"
        mv -f "$DCP/old_.lst" "$DCP/old.lst"
        cp -f "$DCP/1.lst" "$DCP/.1.lst"
        rm "$DT/nmfile"
    }

    conditions ${2}
    if [[ ${2} = 1 ]]; then echo "Podcasts" > "$DC_s/tpa"; fi
    rm "$DM_tl/Podcasts"/*.updt
    > "$updt"
    echo -e "$(gettext "Latest downloads:") 0" \
    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Podcasts/$date.updt"
    fetch_podcasts

    kept_episodes=0
    [ -e "$DCP/2.lst" ] && kept_episodes=$(wc -l < "$DCP/2.lst")
    new_episodes=0
    [ -e "$DT_r/log" ] && new_episodes=$(wc -l < "$DT_r/log")
    export new_episodes

    cleanups "$updt" "$DT/out.xml"
    find "$DT_r" -maxdepth 1 -type d -name '*.dl_poddir' -exec rm -fr {} \;
    find "$DM_tl/Podcasts" -maxdepth 1 -type f -name '*.updt' -delete

    echo -e "$(gettext "Updated:") $(date "+%r %a %d %B")
    \r$(gettext "Latest downloads:") $new_episodes" \
    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Podcasts/$date.updt"

    if [[ ${new_episodes} -gt 0 ]]; then
        if [[ ${new_episodes} -eq 1 ]]; then
            notify-send -i idiomind "$(gettext "New content")" \
            "$(gettext "1 episode downloaded")" -t 8000
        elif [[ ${new_episodes} -gt 1 ]]; then
            notify-send -i idiomind "$(gettext "New content")" \
            "$(gettext "$new_episodes episodes downloaded")" -t 8000
        fi
        cleanups "$DC_a/Podcasts${tlng}_tsk"
       
        if [ ${ait} -gt 0 ]; then
            lbltp="$(gettext "Listen: Recent audios")"
            echo -e "${lbltp}" >> "$DC_a/Podcasts${tlng}_tsk"
        fi
        if [ ${vit} -gt 0 ]; then
            lbltp="$(gettext "Watch: Recent videos")"
            echo -e "${lbltp}" >> "$DC_a/Podcasts${tlng}_tsk"
        fi
 
        idiomind tasks
        removes
    else
        if [[ ${2} = 1 ]]; then
            notify-send -i idiomind \
            "$(gettext "Update finished")" \
            "$(gettext "Has not changed since last update")" -t 8000
        fi
    fi
    cfg="$DM_tl/Podcasts/.conf/podcasts.cfg"; if [ -f "$cfg" ]; then
    sync="$(grep -o 'sync="[^"]*' "$cfg" | grep -o '[^"]*$')"
        if [ "$sync" = TRUE ]; then
            if [[ ${2} = 1 ]]; then 
                "$DSP/podcasts.sh" sync 1
            else
                "$DSP/podcasts.sh" sync 0
            fi
        fi
    fi
    exit
} >/dev/null 2>&1


function vwr() {
    sz=(660 380); [[ ${swind} = TRUE ]] && sz=(540 300)
    dir="$DM_tl/Podcasts/cache"
    fname=$(echo -n "${item}" | md5sum | rev | cut -c 4- | rev)
    channel="$(grep -o channel=\"[^\"]* "$dir/${fname}.item" |grep -o '[^"]*$')"
    if grep -Fxo "${item}" < "$DM_tl/Podcasts/.conf/2.lst"; then
        btnlabel="!list-remove!$(gettext "Remove from favorites")"
        btncmd="$DSP/cnfg.sh 'remove_item'"
    else
        btnlabel="!emblem-favorite!$(gettext "Add to favorites")"
        btncmd="'$DSP/podcasts.sh' new_item"
    fi
    btncmd2="'$DSP/podcasts.sh' save_as"
    _width=${sz[0]}; _height=${sz[1]}
    if [ -f "$dir/$fname.html" ]; then
        uri="$dir/$fname.html"
    else
        source "$DS/ifs/cmns.sh"
        rm_item 1; rm_item 2
        msg "$(gettext "No such file or directory")\n${topic}\n" error Error & exit 1
    fi
    	export uri channel _height _width

python3 <<PY
import gi
gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import WebKit2, Gtk
import os
uri = os.environ['uri']
channel = os.environ['channel']
_width = os.environ['_width']
_height = os.environ['_height']
class MainWin(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self, title = channel, 
        skip_pager_hint=True, skip_taskbar_hint=True)
        self.set_size_request(int(_width), int(_height))
        self.view = WebKit2.WebView()
        self.view.load_uri("file://" + uri)
        box = Gtk.Box()
        self.add(box)
        box.pack_start(self.view, True, True, 0)
        self.show_all()
if __name__ == '__main__':
    mainwin = MainWin()
    Gtk.main()
PY
}

function set_channel() {
    internet
    if [[ -z "${2}" ]]; then cleanups "$DCP/${3}.rss"; exit 1; fi
    feed="${2}"
    num="${3}"
    # head
    feed_dest="$(curl -Ls -o /dev/null -w %{url_effective} "${feed}")"
    curl "${feed_dest}" |sed '1{/^$/d}' > "$DT/rss.xml"
    xml="$(xsltproc "$DS/default/ch.xml" "$DT/rss.xml")"
    xml="$(echo -e "${xml}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
    items1="$(echo "${xml}"  |tr '\n' ' ' \
    | tr -s '[:space:]' |sed 's/EOL/\n/g' |sed -r 's|-\!-|\n|g')"
    # content t1
    xml="$(xsltproc "$DS/default/tp1.xml" "$DT/rss.xml")"
    xml="$(echo -e "${xml}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
    items2="$(echo "${xml}" |tr '\n' ' ' |tr -s "[:space:]" \
    | sed 's/EOL/\n/g' |head -n 1 |sed -r 's|-\!-|\n|g')"
    
    # content t2
    xml="$(xsltproc "$DS/default/tp2.xml" "$DT/rss.xml")"
    xml="$(echo -e "${xml}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
    items4="$(echo "${xml}" |tr '\n' ' ' |tr -s "[:space:]" \
    | sed 's/EOL/\n/g' |head -n 1 |sed -r 's|-\!-|\n|g')"

    fchannel() {
        n=1
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 -a -z "${name}" ]; then name="${get}"; n=2; fi
            if [ -n "$(grep 'http:/' <<< "${get}")" -a -z "${link}" ]; then link="${get}"; n=3; fi
            if [ -n "$(grep -E '.jpeg|.jpg|.png' <<< "${get}")" -a -z "${logo}" ]; then logo="${get}"; fi
            let n++
        done <<< "${items1}"
    }
    # --------------------------------------
    ftype1() {
        n=1
        while read -r get; do
            [[ ${n} = 3 || ${n} = 5 || ${n} = 6 ]] && continue
            if [ -n "$(grep -o -E '\.mp3|\.mp4|\.ogg|\.avi|\.m4v|\.m4a|\.mov|\.flv' <<< "${get}")" -a -z "${media}" ]; then
            media="$n"; type=1; break; fi
            let n++
        done <<< "${items2}"
        f3="$(sed -n 3p <<< "${items2}")"
        f5="$(sed -n 5p <<< "${items2}")"
        f6="$(sed -n 6p <<< "${items2}")"
        if [ $(wc -w <<< "$f3") -ge 2 -a $(wc -w <<< "${f3}") -le 200 ]; then title=3; fi
        if [ $(wc -w <<< "${f5}") -ge 2 -a -n "$(grep -o -E '\<|\>|/>' <<< "${f5}")" ]; then sum1=5; fi
        if [ $(wc -w <<< "${f6}") -ge 2 -a -n "$(grep -o -E '\<|\>|/>' <<< "${f6}")" ]; then sum1=6; fi
        if [ $(wc -w <<< "${f5}") -ge 2 ]; then sum2=5; fi
        if [ $(wc -w <<< "${f6}") -ge 2 ]; then sum2=6; fi
    }
    
    ftype2() {
        n=1
        while read -r get; do
            echo "$get........."
            if [ -n "$(grep -o -E '\.jpg|\.jpeg|\.png' <<< "${get}")" -a -z "${image}" ]
            then image="$n"; fi
            let n++
        done <<< "${items4}"
        
        n=3
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 -a -z "${title}" ]; then title="$n"; break; fi
            let n++
        done <<< "{$items4}"
        
        n=6
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 -a -z "${summ}" ]; then summ="$n"; type=2; break; fi
            let n++
        done <<< "${items4}"
    }

    fchannel
    
    ftype1
    
    if [[ ${type} != 1 ]]; then
        ftype2
    fi
    
    # --------------------------------------
    if [ -z "$sum2" ]; then
        summary="${sum1}"
    else
        summary="${sum2}"
    fi
    if [[ -z "${title}" ]]; then
        type=3
    fi

    title=$(echo "${title}" | sed 's/\://g' \
    | sed 's/\&quot;/\"/g' | sed "s/\&#39;/\'/g" \
    | sed 's/\&/and/g' | sed 's/^\s*./\U&\E/g' \
    | sed 's/<[^>]*>//g' | sed 's/^ *//; s/ *$//; /^$/d')

    if [[ ${type} = 1 ]] || [[ ${type} = 2 ]]; then
        cfg="channel=\"$name\"
        \rlink=\"$link\"
        \rlogo=\"$logo\"
        \rntype=\"$type\"
        \rnmedia=\"$media\"
        \rntitle=\"$title\"
        \rnsumm=\"$summary\"
        \rnimage=\"$image\"
        \rurl=\"$feed_dest\""
        echo -e "${cfg}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DCP/$num.rss"
    else
        url="$(tr '&' ' ' <<< "${feed}")"
        msg "<b>$(gettext "Specified URL doesn't seem to contain any feeds:")</b>\n$url\n" dialog-warning Idiomind &
        > "$DCP/$num.rss"
    fi
    cleanups "$DT/rss.xml"
    exit 1
}

function sync() {
    cfg="$DM_tl/Podcasts/.conf/podcasts.cfg"
    path="$(grep -o 'path="[^"]*' "$cfg" |grep -o '[^"]*$')"
    synf="$(grep -o 'synf="[^"]*' "$cfg" |grep -o '[^"]*$')"
    
    if [ -f "$DT/l_sync" ] && [[ ${2} -ge 1 ]]; then
        msg_4 "$(gettext "A process is already running!")" \
        "$DS/images/warning.png" "OK" "$(gettext "Stop")" "$(gettext "Syncing...")"
        e=$?
        if [ $e -eq 1 ]; then
            killall rsync
            if ps -A | pgrep -f "rsync"; then killall rsync; fi
            cleanups "$DT/l_sync" "$DT/cp.lock"
            killall podcasts.sh
            exit 1
        fi
    elif [ -e "$DT/l_sync" ] && [[ ${2} = 0 ]]; then
        exit 1
    elif [ ! -d "$path" ] && [[ ${2} -ge 1 ]]; then
        msg " $(gettext "The directory to synchronization does not exist.")\n" \
        dialog-warning "$(gettext "Warning")"
        cleanups "$DT/l_sync"; exit 1
        
        elif  [ ! -d "$path" ] && [[ ${2} = 0 ]]; then
        echo "Synchronization error. Missing path" >> "$DM_tl/Podcasts/.conf/feed.err"
        cleanups "$DT/l_sync"; exit 1
    elif [ -d "${path}" ]; then
        touch "$DT/l_sync"; SYNCDIR="${path}/"
        if [ ${synf} = TRUE ]; then
            > "$DT/rsync_list"
            while read item; do
                if [ -e "$DMC/$(nmfile "${item}").mp3" ]; then
                    echo "./$(nmfile "${item}").mp3" >> "$DT/rsync_list"
                elif [ -e "$DMC/$(nmfile "${item}").mp4" ]; then
                    echo "./$(nmfile "${item}").mp4" >> "$DT/rsync_list"
                elif [ -e "$DMC/$(nmfile "${item}").m4v" ]; then
                    echo "./$(nmfile "${item}").m4v" >> "$DT/rsync_list"
                elif [ -e "$DMC/$(nmfile "${item}").m4a" ]; then
                    echo "./$(nmfile "${item}").m4a" >> "$DT/rsync_list"
                fi
            done < <(cat "$DCP/2.lst")
        fi
        cd /
        if [[ ${new_episodes} -gt 0 || ${2} = 2 || ${synf} = TRUE ]]; then
            if [ ${rsync_delete} = 0 ]; then
                if [ ${synf} = TRUE ]; then
                    rsync -am --stats --omit-dir-times --ignore-errors --log-file="$DT/l_sync" \
                    --files-from="$DT/rsync_list" "$DM_tl/Podcasts/cache/" "${SYNCDIR}"
                    exit=$?
                else
                    rsync -am --stats --exclude="*.item" --exclude="*.png" \
                    --exclude="*.html" --omit-dir-times --ignore-errors \
                    --log-file="$DT/l_sync" "$DM_tl/Podcasts/cache/" "${SYNCDIR}"
                    exit=$?
                fi
            elif [ ${rsync_delete} = 1 ]; then 
                if [ ${synf} = TRUE ]; then
                    rsync -am --stats --delete --omit-dir-times --ignore-errors --log-file="$DT/l_sync" \
                    --files-from="$DT/rsync_list" "$DM_tl/Podcasts/cache/" "${SYNCDIR}"
                    exit=$?
                else
                    rsync -am --stats --delete --exclude="*.item" --exclude="*.png" \
                    --exclude="*.html" --omit-dir-times --ignore-errors \
                    --log-file="$DT/l_sync" "$DM_tl/Podcasts/cache/" "${SYNCDIR}"
                    exit=$?
                fi
            fi
            if [ $exit != 0 ]; then
                if [[ ${2} -ge 1 ]]; then
                    (sleep 1 && notify-send -i idiomind \
                    "$(gettext "Error")" \
                    "$(gettext "Error while syncing")" -t 8000) &
                elif [[ ${2} = 0 ]]; then
                    echo "$(gettext "Error while syncing") - $(cat "$DT/l_sync")" >> "$DM_tl/Podcasts/.conf/feed.err"
                fi
            else
                sum="$(cat "$DT/l_sync" |sed 's/^.*]//;/\+/d;/^$/d;s/^ *//' |head -n5 |tail -n4)"
                [[ ${2} -ge 1 ]] && sleep 1 && notify-send -i idiomind \
                "$(gettext "Synchronization finished")" \
                "${sum}" -t 8000
            fi
        fi
        cleanups "$DT/l_sync" "$DT/rsync_list"
        exit
    fi
} >/dev/null 2>&1
 

function tasks() {

    if [[ "$2" = "$(gettext "Watch: Recent videos")"* ]]; then
        "$DS/stop.sh" 2; echo "1" > "$DT/playlck"; sleep 1
        "$DS/ifs/mods/chng/podcasts.sh" "_video_"
    elif [[ "$2" = "$(gettext "Listen: Recent audios")"* ]]; then
        "$DS/stop.sh" 2; echo "1" > "$DT/playlck"; sleep 1
        "$DS/ifs/mods/chng/podcasts.sh" "_audio_"
    else
        export item
        vwr
    fi
} >/dev/null 2>&1


function new_item() {
    DMC="$DM_tl/Podcasts/cache"
    DCP="$DM_tl/Podcasts/.conf"
    if ! grep -Fx "${item}" < "$DCP/2.lst"; then
        fname="$(nmfile "${item}")"
        if [ -s "$DCP/2.lst" ]; then
            sed -i -e "1i$item\\" "$DCP/.2.lst"
            sed -i -e "1i$item\\" "$DCP/2.lst"
        else
            echo "$item" > "$DCP/.2.lst"
            echo "$item" > "$DCP/2.lst"
        fi
        check_index1 "$DCP/2.lst" "$DCP/.2.lst"
        notify-send -i dialog-ok-apply "$(gettext "Saved to Favorites list")" -t 2000
    fi
    exit 0
}

function save_as() {
    fname=$(echo -n "${item}" |md5sum |rev |cut -c 4- |rev)
    [ -f "$DMC/$fname.mp3" ] && file="$DMC/$fname.mp3"
    [ -f "$DMC/$fname.ogg" ] && file="$DMC/$fname.ogg"
    [ -f "$DMC/$fname.m4v" ] && file="$DMC/$fname.m4v"
    [ -f "$DMC/$fname.m4a" ] && file="$DMC/$fname.m4a"
    [ -f "$DMC/$fname.mp4" ] && file="$DMC/$fname.mp4"
    cd "$HOME"
    sv=$(yad --file --save --title="$(gettext "Save as")" \
    --filename="$item${file: -4}" \
    --window-icon=idiomind \
    --skip-taskbar --center --on-top \
    --width=600 --height=500 --borders=10 \
    --button="$(gettext "Cancel")":1 \
    --button="$(gettext "Save")":0)
    ret=$?
    if [ $ret -eq 0 ]; then cp "${file}" "${sv}"; fi
}

function remove_item() {
    touch "$DT/ps_lk"
    fname="$(nmfile "${item}")"
    if grep -Fxo "$item" < "$DCP/2.lst"; then
        if ! grep -Fxo "$item" < "$DCP/1.lst"; then
            msg_2 "$(gettext "Are you sure you want to delete this episode from favorites?")\n" edit-delete "$(gettext "Yes")" "$(gettext "Cancel")" "$(gettext "Confirm")"
            ret="$?"
            if [ $ret -eq 0 ]; then
                if [ -n "$fname" ]; then
                    find "$DMC" -maxdepth 1 -type f -name "$fname.*" -exec rm {} +
                fi
                rm_item 2
            fi
        else
            notify-send -i dialog-ok-apply "$(gettext "Episode removed from favorites")" "$(gettext "Close and reopen the main window to see any changes")"
            rm_item 2
        fi
    fi
    cleanups "$DT/ps_lk"; exit 1
}

function rm_item() {
    local file="$DM_tl/Podcasts/.conf/${1}.lst"
    grep -vxF "${item}" "$file" > "$file.tmp"
    sed '/^$/d' "$file.tmp" > "$file"; rm "$file.tmp"
    local file="$DM_tl/Podcasts/.conf/.${1}.lst"
    grep -vxF "${item}" "$file" > "$file.tmp"
    sed '/^$/d' "$file.tmp" > "$file"; rm "$file.tmp"
}

function delete_all() {
    if [[ $(wc -l < "$DCP/2.lst") -gt 0 ]]; then
    chk="--field="$(gettext "Also delete saved episodes")":CHK"; fi
    if [[ $(wc -l < "$DCP/1.lst") -lt 1 ]]; then exit 1; fi
    dl=$(yad --form --title="$(gettext "Confirm")" \
    --image='edit-delete' \
    --name=Idiomind --class=Idiomind \
    --always-print-result --print-all --separator="|" \
    --window-icon=$DS/images/logo.png --center --on-top \
    --width=400 --height=120 --borders=3 \
    --text="$(gettext "Are you sure you want to delete all episodes?")  " "$chk" \
    --button="$(gettext "Cancel")":1 \
    --button="$(gettext "Yes")":0)
    ret="$?"
    if [ $ret -eq 0 ]; then
        set -e
        if [ -d "$DM_tl/Podcasts/cache" ]; then
            rm "$DM_tl/Podcasts/cache"/*
        fi
        cleanups "$DM_tl/Podcasts/.conf/1.lst" "$DM_tl/Podcasts/$date"
        touch "$DM_tl/Podcasts/.conf/1.lst"
        if [[ $(cut -d "|" -f1 <<< "$dl") = TRUE ]]; then
            cleanups "$DCP/2.lst" "$DCP/.2.lst"
            touch "$DCP/2.lst" "$DCP/.2.lst"
        fi
    fi
    exit
}

case "$1" in
    update)
    update "$@" ;;
    podmode)
    podmode "$@" ;;
    viewer)
    vwr ;;
    dlg_subs)
    dlg_subs ;;
    dlg_optns)
    dlg_optns ;;
    dlg_links)
    dlg_links ;;
    set_channel)
    set_channel "$@" ;;
    sync)
    sync "$@" ;;
    tasks)
    tasks "$@" ;;
    new_item)
    new_item ;;
    save_as)
    save_as ;;
    remove_item)
    remove_item ;;
    delete_all)
    delete_all ;;
    *)
    dlg_config ;;
esac

