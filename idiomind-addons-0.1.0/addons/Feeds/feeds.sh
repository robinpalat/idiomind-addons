#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
sz=(580 560 440); [[ ${swind} = TRUE ]] && sz=(480 460 340)
CNF="$(gettext "Configure")"
source "$DS/ifs/cmns.sh"
DMC="$DM_tl/Feeds/cache"
DMP="$DM_tl/Feeds"
DSP="$DS_a/Feeds"
dfimg="$DSP/images/audio.png"
updt="$DT/updating_feeds"
date=$(date +%d)
DCP="$DM_tl/Feeds/.conf"
downloads=2
rsync_delete=0
eyed3_encoding=utf8

function dlg_config() {
    f=0; cfg=0
    sets=( 'update' 'sync' 'synf' 'path' \
    'eaudio' 'evideo' 'e_keep' 'altrau' 'altrvi' )
    check_dir "$DM_tl/Feeds" "$DM_tl/Feeds/.conf" "$DM_tl/Feeds/cache"
    if [ ! -e "$DM_tl/Feeds/.conf/stts" ]; then f=1
    else 
        [ $(< "$DM_tl/Feeds/.conf/stts") != 12 ] && f=1
    fi
    if [ -e "$DCP/feeds.cfg" ]; then
        [[ $(egrep -cv '#|^$' < "$DCP/feeds.cfg") = 9 ]] && cfg=1
    else 
        > "$DCP/feeds.cfg"
    fi
    if [ ${f} = 1 ]; then
        cd "$DM_tl/Feeds/.conf/"
        touch "./feeds.cfg" "./1.lst" "./2.lst" "./feeds.lst" "./old.lst"
        echo 12 > "$DM_tl/Feeds/.conf/stts"
        echo " " > "$DM_tl/Feeds/.conf/info"
        echo -e "\n$(gettext "Latest downloads:") 0"
        > "$DM_tl/Feeds/cache/.CACHEDIR"
        > "$DM_tl/Feeds/$date.updt"
        "$DS/mngr.sh" mkmn 0
    fi
    [ -e "$DT/cp.lock" ] && kill $(cat "$DT/cp.lock")
    echo $$ > "$DT/cp.lock"
    touch "$DM_tl/Feeds"
    check_file "$DCP/feeds.lst"
    n=1
    while read -r feed; do
        declare url${n}="$feed"
        ((n=n+1))
    done < "$DCP/feeds.lst"
    n=0
    if [ ${cfg} = 1 ]; then
        while [ ${n} -le 8 ]; do
            get="${sets[${n}]}"
            val=$(grep -o "$get"=\"[^\"]* "$DCP/feeds.cfg" |grep -o '[^"]*$')
            declare ${sets[${n}]}="$val"
            ((n=n+1))
        done
    else
        > "$DCP/feeds.cfg"
        while [ ${n} -le 8 ]; do
            echo -e "${sets[${n}]}=\"\"" >> "$DCP/feeds.cfg"
            ((n=n+1))
        done
    fi
    apply() {
        echo -e "${CNFG}" |sed 's/|/\n/g' |sed -n 2,14p | \
        sed 's/^ *//; s/ *$//g' > "$DT/feeds.tmp"
        n=1; echo
        while read feed; do
            declare mod${n}="${feed}"
            mod="mod${n}"; url="url${n}"
            if [ ! -e "$DCP/${n}.rss" -a -n "${!mod}" ]; then
                echo "  -- set channel (noconfig) ${!mod} ${n}"
                "$DSP/feeds.sh" set_channel "${!mod}" ${n} &
            elif [ "${!url}" != "${!mod}" ]; then
                echo "  -- set channel (mod) ${!mod} ${n}"
                "$DSP/feeds.sh" set_channel "${!mod}" ${n} &
            elif [ ! -s "$DCP/${n}.rss" -a -n "${!mod}" ]; then
                echo "  -- set channel (noconfig) ${!mod} ${n}"
                "$DSP/feeds.sh" set_channel "${!mod}" ${n} & fi
            ((n=n+1))
        done < "$DT/feeds.tmp"
        echo
        feeds_tmp="$(cat "$DT/feeds.tmp")"
        if [ -n "$feeds_tmp" ] && [[ "$feeds_tmp" != "$(cat "$DCP/feeds.lst")" ]]; then
        mv -f "$DT/feeds.tmp" "$DCP/feeds.lst"; else rm -f "$DT/feeds.tmp"; fi
        val1=$(cut -d "|" -f17 <<< "$CNFG")
        val2=$(cut -d "|" -f19 <<< "$CNFG")
        val3=$(cut -d "|" -f21 <<< "$CNFG")
        val4=$(cut -d "|" -f22 <<< "$CNFG" |sed 's|/|\\/|g')
        val5=$(cut -d "|" -f23 <<< "$CNFG" |sed 's|/|\\/|g')
        val6=$(cut -d "|" -f25 <<< "$CNFG" |sed 's|/|\\/|g')
        if [ ! -d "$val5" -o -z "$val5" ]; then path=FALSE; fi
        sed -i "s/update=.*/update=\"${val1}\"/g" "$DCP/feeds.cfg"
        sed -i "s/altrau=.*/altrau=\"${val2}\"/g" "$DCP/feeds.cfg"
        sed -i "s/altrvi=.*/altrvi=\"${val3}\"/g" "$DCP/feeds.cfg"
        sed -i "s/sync=.*/sync=\"${val4}\"/g" "$DCP/feeds.cfg"
        sed -i "s/synf=.*/synf=\"${val5}\"/g" "$DCP/feeds.cfg"
        sed -i "s/path=.*/path=\"${val6}\"/g" "$DCP/feeds.cfg"
        cleanups "$DT/cp.lock"
    }

    if [ ! -d "${path}" -o ! -n "${path}" ]; then path=/FALSE; fi
        if [ -f "$DM_tl/Feeds/.conf/feed.err" ]; then
        e="$(head -n 4 < "$DM_tl/Feeds/.conf/feed.err" |sed 's/\&/\&amp\;/g' |awk '!a[$0]++')"
        rm "$DM_tl/Feeds/.conf/feed.err"
        ( sleep 2 && msg "$e\n\t" dialog-information "$(gettext "Errors found")" ) &
        fi
    LANGUAGE_TO_LEARN="$(gettext ${tlng})"
    CNFG="$(yad --form --title="$(gettext "Configure feeds to learn") $LANGUAGE_TO_LEARN" \
    --name=Idiomind --class=Idiomind \
    --always-print-result --print-all --separator="|" \
    --window-icon=idiomind \
    --scroll --on-top --mouse \
    --width=520 --height=340 --borders=8 \
    --field="$(gettext "URLs")":LBL " " \
    --field="" "${url1}" --field="" "${url2}" --field="" "${url3}" \
    --field="" "${url4}" --field="" "${url5}" --field="" "${url6}" \
    --field="" "${url7}" --field="" "${url8}" --field="" "${url9}" \
    --field="" "${url10}" --field="" "${url11}" --field="" "${url12}" \
    --field="$(gettext "Search Feeds")":FBTN "$DSP/feeds.sh 'disc_podscats'" \
    --field="":LBL " " \
    --field="\n":LBL " " \
    --field="$(gettext "Checks for new news at startup")":CHK "$update" \
    --field="$(gettext "Use this audio player")":LBL " " \
    --field="" "$altrau" \
    --field="$(gettext "Use this video player")":LBL " " \
    --field="" "$altrvi" \
    --field="$(gettext "Sync after update")":CHK "$sync" \
    --field="$(gettext "Sync only favorites")":CHK "$synf" \
    --field="$(gettext "Path where news should be synced")":LBL " " \
    --field="":DIR "$path" \
    --field="$(gettext "Synchronize")":FBTN "$DSP/feeds.sh 'sync' 2" \
    --button="$(gettext "Remove")":"$DSP/cnfg.sh 'delete_all'" \
    --button="$(gettext "Cancel")":1 \
    --button="$(gettext "Save")":0)"
    ret=$?
    if [ $ret -eq 0 ]; then apply; fi
    cleanups "$DT/cp.lock"
    exit
}

function feedmode() {
    nmfile() { echo -n "${1}" |md5sum |rev |cut -c 4- |rev; }
    function _list_1() {
        while read -r list1; do
            if [ -e "$DMP/cache/$(nmfile "$list1").png" ]; then
                echo "$DMP/cache/$(nmfile "$list1").png"
            else 
                echo "$DS_a/Feeds/images/audio.png"; fi
            echo "$list1"
        done < "$DCP/1.lst"
    }
    function _list_2() {
        while read -r list2; do
            if [ -e "$DMP/cache/$(nmfile "$list2").png" ]; then
                echo "$DMP/cache/$(nmfile "$list2").png"
            else
            echo "$DS_a/Feeds/images/audio.png"; fi
            echo "$list2"
        done < "$DCP/2.lst"
    }

    nt="$DCP/info"
    fdit=$(mktemp "$DT/fdit.XXXXXX")
    c=$(echo $(($RANDOM%100000))); KEY=$c
    if [ -d "$DT"/*.dl_poddir ]; then
        info="$(gettext "Downloading new news...")"
    elif [ -e ${updt} ]; then
        info="$(gettext "Checking for new news...")"
    else
        info="$(gettext "Feeds")"
    fi
    infolabel="$(< "$DMP"/*.updt)"
    _list_1 | yad --list --tabnum=1 \
    --plug=$KEY --print-all \
    --dclick-action="$DSP/cnfg.sh viewer" \
    --no-headers --expand-column=2 \
    --ellipsize=end --wrap-width=${sz[2]} --ellipsize-cols=1 \
    --column=Name:IMG \
    --column=Name:TXT &
    _list_2 | yad --list --tabnum=2 \
    --plug=$KEY --print-all \
    --dclick-action="$DSP/cnfg.sh viewer" \
    --no-headers --expand-column=2 \
    --ellipsize=end --wrap-width=${sz[2]} --ellipsize-cols=1 \
    --column=Name:IMG \
    --column=Name:TXT &
    yad --text-info --text-align=right --tabnum=3 \
    --text="<small>$infolabel</small>" \
    --plug=$KEY --filename="${nt}" \
    --wrap --editable \
    --margins=14 --fontname='vendana 11' > "${fdit}" &
    yad --notebook --title="Idiomind - $info" \
    --name=Idiomind --class=Idiomind --key=$KEY \
    --always-print-result \
    --window-icon=idiomind --image-on-top \
    --ellipsize=END --align=right --center --fixed \
    --width=${sz[0]} --height=${sz[1]} --borders=5 --tab-borders=0 \
    --tab=" $(gettext "News") " \
    --tab=" $(gettext "Keep") " \
    --tab=" $(gettext "Note") " \
    --button="$(gettext "Update")":2 \
    --button="$(gettext "Close")"!'window-close':1
    ret=$?
    note_mod="$(< "${fdit}")"
    if [ "${note_mod}" != "$(< "${nt}")" ]; then
        if ! grep '^$' < <(sed -n '1p' "${fdit}")
        then echo -e "\n${note_mod}" > "${nt}"
        else echo "${note_mod}" > "${nt}"; fi
    fi
    if [ $ret -eq 2 ]; then "$DSP/feeds.sh" update 1; fi
    cleanups "${fdit}"
} 

function update() {
    include "$DS/ifs/mods/add"
    sets=( 'channel' 'link' 'logo' 'ntype' 'nmedia' 'ntitle' 'nsumm' 'nimage' 'url' )

    conditions() {
        if ps -A |pgrep -f "feeds.sh set_channel"; then
            for s in {1..60}; do
                if ps -A |pgrep -f "feeds.sh set_channel"; then
                    sleep 1; else break; fi
            done
        fi
        check_file "$DCP/1.lst" "$DCP/2.lst" \
        "$DCP/.1.lst" "$DCP/.2.lst"

        if [ -e "$updt" ] && [[ ${1} = 1 ]]; then
            msg_4 "$(gettext "Wait until it finishes a previous process")." \
            "$DS/images/warning.png" OK "$(gettext "Stop")" "$(gettext "Information")"
            ret=$?
            if [ $ret -eq 1 ]; then
                sed -i "/$(gettext "Downloading")/d" "$DM_tl/Feeds/$date.updt"
                cleanups "$updt"
                find "$DT_r" -maxdepth 1 -type d -name '*.dl_poddir' -exec rm -fr {} \;
                "$DS/addons/Feeds/cnfg.sh" stop
            fi
            exit 1
        elif [ -e "$updt" ] && [[ ${1} = 0 ]]; then
            exit 1
        fi
        if [ -e "$DCP/2.lst" ] && [[ $(wc -l < "$DCP/2.lst") \
        != $(wc -l < "$DCP/.2.lst") ]]; then
            cp "$DCP/.2.lst" "$DCP/2.lst"
        fi
        if [ -e "$DCP/1.lst" ] && [[ $(wc -l < "$DCP/1.lst") \
        != $(wc -l < "$DCP/.1.lst") ]]; then
            cp "$DCP/.1.lst" "$DCP/1.lst"
        fi
        if [[ "$(< "$DCP/stts")" != 12 ]]; then
            echo 12 > "$DCP/stts"
        fi
        check_dir "$DM_tl/Feeds/cache" "$DM_tl/Feeds/.conf"
        check_file "$DCP/old.lst"
        export cntfeeds=$(sed '/^$/d' < "$DCP/feeds.lst" |wc -l)
        if [[ ${cntfeeds} -le 0 ]]; then
            [[ ${1} = 1 ]] && msg "$(gettext "Missing URL. Please check the settings in the preferences dialog.")\n" dialog-information
            cleanups "$updt" "$DT_r"
            exit 1
        fi
        if [[ ${1} = 1 ]]; then internet; else curl -v www.google.com 2>&1 \
        | grep -m1 "HTTP/1.1" >/dev/null 2>&1 || exit 1; fi
    }

    mediatype() {
        if echo "$1" |grep -q ".jpg"; then ex=jpg
        elif echo "$1" |grep -q ".jpeg"; then ex=jpeg
        elif echo "$1" |grep -q ".png"; then ex=png
        elif echo "$1" |grep -q ".PNG"; then ex=png
        elif echo "$1" |grep -q ".JPG"; then ex=jpg
        elif echo "$1" |grep -o ".pdf"; then ex=pdf
        export ex
        else
        echo -e "$(gettext "Could not add some feeds:")\n$FEED" >> "$DM_tl/Feeds/.conf/feed.err"
        return; fi
    }

    mkhtml() {
        itm="$DMC/$fname.html"
        video="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/vwr.css\">
        \r<video width=640 height=380 controls>
        \r<source src=\"$fname.$ex\" type=\"video/mp4\">
        \rYour browser does not support the video tag.</video>"
        audio="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/vwr.css\">
        \r<br><div class=\"title\"><h2><a href=\"$link\">$title</a></h2></div><br>
        \r<div class=\"summary\"><audio controls><br>
        \r<source src=\"$fname.$ex\" type=\"audio/mpeg\">
        \rYour browser does not support the audio tag.</audio><br><br>
        \r$summary<br><br></div>"
        text="<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />
        \r<link rel=\"stylesheet\" href=\"/usr/share/idiomind/default/vwr.css\">
        \r<body><br><div class=\"title\"><h2><a href=\"$link\">$title</a></h2></div><br>
        \r<div class=\"summary\"><div class=\"image\">
        \r<img src=\"$fname.jpg\" alt=\"Image\" style=\"width:650px\"></div><br>
        \r$summary<br><br></div>
        \r</body>"
        if [[ ${tp} = vid ]]; then
            if [ $ex = m4v -o $ex = mp4 ]; then t=mp4
            elif [ $ex = avi ]; then t=avi; fi
            echo -e "${video}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$itm"
        elif [[ ${tp} = aud ]]; then
            echo -e "${audio}" |sed -e 's/^[ \t]*//' |tr -d '\n' > "$itm"
        fi
    }

    get_images() {
        find "$DT_r" -maxdepth 1 -type f -regextype posix-extended \
        -iregex '.*\.(jpg|jpeg|png|JPG|JPEG|PNG)$' -delete
        
        if [ "$tp" = aud ]; then
            p=1; t=1; unset img
            eyeD3 --write-images "$DT_r" "$DT_r/media.$ex"
            img="$(ls |grep -E '.jpeg|.JPEG|.jpg|.JPG|.png|.PNG' |head -n1)"
            
            if [ ! -f "$DT_r/$img" ]; then
                wget -q -O- "$FEED" |grep -o '<itunes:image href="[^"]*' \
                |grep -o '[^"]*$' |xargs wget -c
                img="$(ls |grep -E '.jpeg|.JPEG|.jpg|.JPG|.png|.PNG' |head -n1)"
            else
                t=0
            fi
            if [ ! -f "$DT_r/$img" ]; then
                cp -f "$DSP/images/audio.png" "$DMC/$fname.png"; p=0
            fi
        elif [ "$tp" = vid ]; then
            p=1; mplayer -ss 60 -nosound -noconsolecontrols \
            -vo jpeg -frames 3 ./"media.$ex" >/dev/null
            img="$(ls |grep -E '.jpeg|.JPEG|.jpg|.JPG|.png|.PNG' |head -n1)"
            
            if [ ! -f "$DT_r/$img" ]; then
                cp -f "$DSP/images/audio.png" "$DMC/$fname.png"; p=0
            fi
        fi
        if [ ${p} = 1 -a -f "$DT_r/$img" ]; then
            layer="$DSP/images/layer.png"
            [ ${t} = 1 ] && eyeD3 --encoding=$eyed3_encoding \
            --add-image "$DT_r/$img":ILLUSTRATION "$DT_r/media.$ex"
            convert "$DT_r/$img" -interlace Plane -thumbnail 62x54^ \
            -gravity center -extent 62x54 -quality 100% tmp.png
            convert tmp.png -bordercolor white \
            -border 2 \( +clone -background black \
            -shadow 70x3+2+2 \) +swap -background transparent \
            -layers merge +repage tmp.png
            composite -compose Dst_Over tmp.png "${layer}" "$DMC/$fname.png"
        fi
        find "$DT_r" -maxdepth 1 -type f -regextype posix-extended \
        -iregex '.*\.(jpg|jpeg|png|JPG|JPEG|PNG)$' -delete
    }
    
    fetch_feeds() {
        n=0; d=0
        for ln in {1..12}; do
            FEED=$(grep -o "url"=\"[^\"]* "$DCP/${ln}.rss" |grep -o '[^"]*$')
            pporc=$((cntfeeds*downloads))
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
                    #if [ -z "${nmedia}" ]; then
                        #echo -e "  -- no-media! $FEED\n"
                        #> "$DCP/${ln}.rss"
                        #echo -e "$(gettext "Please, reconfigure this feed:")\n$FEED" >> "$DCP/feed.err"
                        #continue
                    #fi
                    if [ "$ntype" = 1 ]; then
                        curl "${FEED}" > "$DT/out.xml"
                        if grep '^$' "$DT/out.xml"; then
                            sed -i '/^$/d' "$DT/out.xml"
                        fi
                        entries="$(xsltproc "$DS/default/tmpl4.xml" "$DT/out.xml")"
                        entries="$(echo -e "${entries}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
                        entries="$(echo "${entries}" | tr '\n' ' ' \
                        | tr -s '[:space:]' | sed 's/EOL/\n/g' | head -n ${downloads})"
                        entries="$(echo "${entries}" | sed '/^$/d')"
                        
                        while read -r item; do
                            fields="$(sed -r 's|-\!-|\n|g' <<< "${item}")"
                            enclosure=$(sed -n ${nmedia}p <<< "${fields}")
                            title=$(echo "${fields}" | sed -n ${ntitle}p | sed 's/\://g' \
                            | sed 's/\&quot;/\"/g' | sed "s/\&#39;/\'/g" \
                            | sed 's/\&/and/g' | sed 's/^\s*./\U&\E/g' \
                            | sed 's/<[^>]*>//g' | sed 's/^ *//; s/ *$//; /^$/d')
                            summary=$(echo "${fields}" | sed -n ${nsumm}p)
                            fname="$(nmfile "${title}")"
                            
                            if [[ ${#title} -ge 300 ]] || [ -z "$title" ]; then
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
                                    mkhtml
                                    if [[ -s "$DCP/1.lst" ]]; then
                                        sed -i -e "1i${title}\\" "$DCP/1.lst"
                                    else 
                                        echo "${title}" > "$DCP/1.lst"
                                    fi
                                    
                                    lbltp="$(gettext "Read:")"
                                    ttitle="$(sed 's/\$/\\$/g' <<< "$title")"
                                    taskItem="$lbltp ${ttitle}"
                                    [  $(wc -c <<< $ttitle) -gt 60 ] && \
                                    taskItem="$lbltp ${ttitle:0:60}..."
                                    if ! grep -Fxq "${taskItem}" "$DC_a/Feeds.tasks" >/dev/null 2>&1; then
                                        echo "${taskItem}" >> "$DC_a/Feeds.tasks"
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
                                    echo -e "<b>$(gettext "Downloading")</b>
                                    \r$(gettext "Latest downloads:") $d" \
                                    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Feeds/$date.updt"
                                fi
                            fi
                        done <<< "${entries}"
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
            if ! grep -Fxq "${r_file}" "$DT/nmfile"; then
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
    if [[ ${2} = 1 ]]; then echo "Feeds" > "$DC_s/tpa"; fi
    rm "$DM_tl/Feeds"/*.updt
    > "$updt"
    echo -e "$(gettext "Updating")
    \r$(gettext "Latest downloads:") 0" \
    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Feeds/$date.updt"
    fetch_feeds

    kept_news=0
    [ -e "$DCP/2.lst" ] && kept_news=$(wc -l < "$DCP/2.lst")
    new_news=0
    [ -e "$DT_r/log" ] && new_news=$(wc -l < "$DT_r/log")
    export new_news

    cleanups "$updt" "$DT/out.xml"
    find "$DT_r" -maxdepth 1 -type d -name '*.dl_poddir' -exec rm -fr {} \;
    find "$DM_tl/Feeds" -maxdepth 1 -type f -name '*.updt' -delete

    echo -e "$(gettext "Last update:") $(date "+%r %a %d %B")
    \r$(gettext "Latest downloads:") $new_news" \
    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Feeds/$date.updt"

    idiomind tasks
    if [[ ${new_news} -gt 0 ]]; then
        if [[ ${new_news} -eq 1 ]]; then
            notify-send -i idiomind "$(gettext "Feeds: New content")" \
            "$(gettext "1 article downloaded")" -t 8000
        elif [[ ${new_news} -gt 1 ]]; then
            notify-send -i idiomind "$(gettext "Feeds: New content")" \
            "$(gettext "$new_news news downloaded")" -t 8000
        fi
        if [ $(cat "$DC_a/Feeds.tasks" |wc -l) -gt 8 ]; then
            awk '!x[$0]++' "$DC_a/Feeds.tasks" |tail -n 8 > "$DT/Feeds.tasks"
            mv -f "$DT/Feeds.tasks" "$DC_a/Feeds.tasks"
        fi
        removes
    else
        if [[ ${2} = 1 ]]; then
            notify-send -i idiomind \
            "$(gettext "Feeds: Update finished")" \
            "$(gettext "Has not changed since last update")" -t 8000
        fi
    fi

    exit
} >/dev/null 2>&1



function vwr() {
    sz=(640 400); [[ ${swind} = TRUE ]] && sz=(540 300)
    dir="$DM_tl/Feeds/cache"
    fname=$(echo -n "${item}" | md5sum | rev | cut -c 4- | rev)
    channel="$(grep -o channel=\"[^\"]* "$dir/${fname}.item" |grep -o '[^"]*$')"
    if grep -Fxo "${item}" "$DM_tl/Feeds/.conf/2.lst"; then
        btnlabel="!list-remove!$(gettext "Remove from favorites")"
        btncmd="$DSP/cnfg.sh 'remove_item'"
    else
        btnlabel="!emblem-favorite!$(gettext "Add to favorites")"
        btncmd="'$DSP/feeds.sh' new_item"
    fi
    btncmd2="'$DSP/feeds.sh' save_as"
    if [ -f "$dir/$fname.html" ]; then
        uri="$dir/$fname.html"
    else
        source "$DS/ifs/cmns.sh"
        rm_item 1; rm_item 2
        msg "$(gettext "No such file or directory")\n${topic}\n" error Error & exit 1
    fi
    #--button="!view-refresh!$(gettext "XXX")":$xxx 'xxx'
    yad --html --title="${channel}" \
    --name=Idiomind --class=Idiomind \
    --encoding=UTF-8 --uri="${uri}" \
    --window-icon=idiomind --center --on-top \
    --width=${sz[0]} --height=${sz[1]}  --borders=0 "$btnre" \
    --button="!document-save-as!$(gettext "Save as")":"${btncmd2}" \
    --button="${btnlabel}":"${btncmd}"
}


function set_channel() {
    type=1
    internet
    if [[ -z "${2}" ]]; then
    cleanups "$DCP/${3}.rss"; exit 1; fi
    feed="${2}"
    num="${3}"
    # head
    feed_dest="$(curl -Ls -o /dev/null -w %{url_effective} "${feed}")"
    curl "${feed_dest}" |sed '1{/^$/d}' > "$DT/rss.xml"
    xml="$(xsltproc "$DS/default/tmpl3.xml" "$DT/rss.xml")"
    xml="$(echo -e "${xml}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
    items1="$(echo "${xml}"  |tr '\n' ' ' \
    | tr -s '[:space:]' |sed 's/EOL/\n/g' |sed -r 's|-\!-|\n|g')"
    # content
    xml="$(xsltproc "$DS/default/tmpl4.xml" "$DT/rss.xml")"
    xml="$(echo -e "${xml}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
    items2="$(echo "${xml}" |tr '\n' ' ' |tr -s "[:space:]" \
    | sed 's/EOL/\n/g' |head -n 1 |sed -r 's|-\!-|\n|g')"

    fchannel() {
        n=1;
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 -a -z "${name}" ]; then name="${get}"; n=2; fi
            if [ -n "$(grep 'http:/' <<< "${get}")" -a -z "${link}" ]; then link="${get}"; n=3; fi
            if [ -n "$(grep -E '.jpeg|.jpg|.png' <<< "${get}")" -a -z "${logo}" ]; then logo="${get}"; fi
            let n++
        done <<< "${items1}"
    }

    ftype2() {
        n=1
        while read -r get; do
            if [ -n "$(grep -o -E '\.jpg|\.jpeg|\.png' <<< "${get}")" -a -z "${image}" ]
            then image="$n"; type=1; break; fi
            let n++
        done <<< "${items3}"
        n=4
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 -a -z "${title}" ]; then title="$n"; break; fi
            let n++
        done <<< "{$items3}"
        n=6
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 -a -z "${summ}" ]; then summ="$n"; break; fi
            let n++
        done <<< "${items3}"
    }
    get_summ() {
        n=1
        while read -r get; do
            if [ $(wc -w <<< "${get}") -ge 1 ]; then summ="$n"; break; fi
            let n++
        done <<< "${items3}"
    }
    fchannel
    ftype2
    if [ -z "$sum2" ]; then
        summary="${sum1}"
    else
        summary="${sum2}"
    fi
    if [[ -z "${title}" ]] || [[ -z "${feed_dest}" ]]; then
        type=3
    fi
    title=$(echo "${title}" | sed 's/\://g' \
    | sed 's/\&quot;/\"/g' | sed "s/\&#39;/\'/g" \
    | sed 's/\&/and/g' | sed 's/^\s*./\U&\E/g' \
    | sed 's/<[^>]*>//g' | sed 's/^ *//; s/ *$//; /^$/d')

    if [[ ${type} = 1 ]]; then
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


function tasks() {
    i="$(echo "$2" |sed -e 's/\.\.\.//;')"
    item="$(grep -m 1 "$i" < "$DCP/1.lst")"
    fname=$(echo -n "${item}" |md5sum |rev |cut -c 4- |rev)
    if [ -f "$DMC/$fname.mp3" ]; then
        pod=$(grep -o "channel"=\"[^\"]* "$DMC/$fname.item" |grep -o '[^"]*$')
        epi=$(grep -o "title"=\"[^\"]* "$DMC/$fname.item" |grep -o '[^"]*$')
        (sleep 2; notify-send -i "idiomind" "${pod}" "${epi}" -t 10000) &
        "$DS/stop.sh" 2; sleep 1
        echo "${item}" > "$DT/play2lck"
        "$DS/ifs/mods/chng/feeds.sh"
    else
        export item
        vwr
    fi
} >/dev/null 2>&1


function new_item() {
    DMC="$DM_tl/Feeds/cache"
    DCP="$DM_tl/Feeds/.conf"
    if ! grep -Fx "${item}" "$DCP/2.lst"; then
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
    if grep -Fxo "$item" "$DCP/2.lst"; then
        if ! grep -Fxo "$item" "$DCP/1.lst"; then
            msg_2 "$(gettext "Are you sure you want to delete this article from favorites?")\n" edit-delete "$(gettext "Yes")" "$(gettext "Cancel")" "$(gettext "Confirm")"
            ret="$?"
            if [ $ret -eq 0 ]; then
                if [ -n "$fname" ]; then
                    find "$DMC" -maxdepth 1 -type f -name "$fname.*" -exec rm {} +
                fi
                rm_item 2
            fi
        else
            notify-send -i dialog-ok-apply "$(gettext "Article removed from favorites")" "$(gettext "Close and reopen the main window to see any changes")"
            rm_item 2
        fi
    fi
    cleanups "$DT/ps_lk"; exit 1
}

function rm_item() {
    local file="$DM_tl/Feeds/.conf/${1}.lst"
    grep -vxF "${item}" "$file" > "$file.tmp"
    sed '/^$/d' "$file.tmp" > "$file"; rm "$file.tmp"
    local file="$DM_tl/Feeds/.conf/.${1}.lst"
    grep -vxF "${item}" "$file" > "$file.tmp"
    sed '/^$/d' "$file.tmp" > "$file"; rm "$file.tmp"
}

function delete_all() {
    if [[ $(wc -l < "$DCP/2.lst") -gt 0 ]]; then
    chk="--field="$(gettext "Also delete saved news")":CHK"; fi
    if [[ $(wc -l < "$DCP/1.lst") -lt 1 ]]; then exit 1; fi
    dl=$(yad --form --title="$(gettext "Confirm")" \
    --image='edit-delete' \
    --name=Idiomind --class=Idiomind \
    --always-print-result --print-all --separator="|" \
    --window-icon=idiomind --center --on-top \
    --width=400 --height=120 --borders=3 \
    --text="$(gettext "Are you sure you want to delete all news?")  " "$chk" \
    --button="$(gettext "Cancel")":1 \
    --button="$(gettext "Yes")":0)
    ret="$?"
    if [ $ret -eq 0 ]; then
        set -e
        if [ -d "$DM_tl/Feeds/cache" ]; then
            rm "$DM_tl/Feeds/cache"/*
        fi
        cleanups "$DM_tl/Feeds/.conf/1.lst" "$DM_tl/Feeds/$date"
        touch "$DM_tl/Feeds/.conf/1.lst"
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
    feedmode)
    feedmode "$@" ;;
    viewer)
    vwr ;;
    set_channel)
    set_channel "$@" ;;
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

