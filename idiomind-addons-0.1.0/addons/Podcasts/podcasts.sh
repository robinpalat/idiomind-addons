#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ -z "$DM" ] && source /usr/share/idiomind/default/c.conf
sz=(580 560 440); [[ ${swind} = TRUE ]] && sz=(480 460 340)
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

function dlg_config() {
    f=0; cfg=0
    sets=( 'update' 'sync' 'synf' 'path' \
    'eaudio' 'evideo' 'e_keep' 'altrau' 'altrvi' )
    check_dir "$DM_tl/Podcasts" "$DM_tl/Podcasts/.conf" "$DM_tl/Podcasts/cache"
    if [ ! -e "$DM_tl/Podcasts/.conf/stts" ]; then f=1
    else 
        [ $(< "$DM_tl/Podcasts/.conf/stts") != 11 ] && f=1
    fi
    if [ -e "$DCP/podcasts.cfg" ]; then
        [[ $(egrep -cv '#|^$' < "$DCP/podcasts.cfg") = 9 ]] && cfg=1
    else 
        > "$DCP/podcasts.cfg"
    fi
    if [ ${f} = 1 ]; then
        cd "$DM_tl/Podcasts/.conf/"
        touch "./podcasts.cfg" "./1.lst" "./2.lst" "./feeds.lst" "./old.lst"
        echo 11 > "$DM_tl/Podcasts/.conf/stts"
        echo " " > "$DM_tl/Podcasts/.conf/info"
        echo -e "\n$(gettext "Latest downloads:") 0"
        > "$DM_tl/Podcasts/cache/.CACHEDIR"
        > "$DM_tl/Podcasts/$date.updt"
        "$DS/mngr.sh" mkmn 0
    fi
    [ -e "$DT/cp.lock" ] && kill $(cat "$DT/cp.lock")
    echo $$ > "$DT/cp.lock"
    touch "$DM_tl/Podcasts"
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
            val=$(grep -o "$get"=\"[^\"]* "$DCP/podcasts.cfg" |grep -o '[^"]*$')
            declare ${sets[${n}]}="$val"
            ((n=n+1))
        done
    else
        > "$DCP/podcasts.cfg"
        while [ ${n} -le 8 ]; do
            echo -e "${sets[${n}]}=\"\"" >> "$DCP/podcasts.cfg"
            ((n=n+1))
        done
    fi
    apply() {
        echo -e "${CNFG}" |sed 's/|/\n/g' |sed -n 2,14p | \
        sed 's/^ *//; s/ *$//g' > "$DT/podcasts.tmp"
        n=1; echo
        while read feed; do
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
        echo
        podcasts_tmp="$(cat "$DT/podcasts.tmp")"
        if [ -n "$podcasts_tmp" ] && [[ "$podcasts_tmp" != "$(cat "$DCP/feeds.lst")" ]]; then
        mv -f "$DT/podcasts.tmp" "$DCP/feeds.lst"; else rm -f "$DT/podcasts.tmp"; fi
        val1=$(cut -d "|" -f17 <<< "$CNFG")
        val2=$(cut -d "|" -f19 <<< "$CNFG")
        val3=$(cut -d "|" -f21 <<< "$CNFG")
        val4=$(cut -d "|" -f22 <<< "$CNFG" |sed 's|/|\\/|g')
        val5=$(cut -d "|" -f23 <<< "$CNFG" |sed 's|/|\\/|g')
        val6=$(cut -d "|" -f25 <<< "$CNFG" |sed 's|/|\\/|g')
        if [ ! -d "$val5" -o -z "$val5" ]; then path=FALSE; fi
        sed -i "s/update=.*/update=\"${val1}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/altrau=.*/altrau=\"${val2}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/altrvi=.*/altrvi=\"${val3}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/sync=.*/sync=\"${val4}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/synf=.*/synf=\"${val5}\"/g" "$DCP/podcasts.cfg"
        sed -i "s/path=.*/path=\"${val6}\"/g" "$DCP/podcasts.cfg"
        cleanups "$DT/cp.lock"
    }

    if [ ! -d "${path}" -o ! -n "${path}" ]; then path=/FALSE; fi
        if [ -f "$DM_tl/Podcasts/.conf/feed.err" ]; then
        e="$(head -n 4 < "$DM_tl/Podcasts/.conf/feed.err" |sed 's/\&/\&amp\;/g' |awk '!a[$0]++')"
        rm "$DM_tl/Podcasts/.conf/feed.err"
        ( sleep 2 && msg "$e\n\t" dialog-information "$(gettext "Errors found")" ) &
        fi
    LANGUAGE_TO_LEARN="$(gettext ${tlng})"
    CNFG="$(yad --form --title="$(gettext "Configure podcasts to learn") $LANGUAGE_TO_LEARN" \
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
    --field="$(gettext "Search Podcasts")":FBTN "$DSP/podcasts.sh 'disc_podscats'" \
    --field="":LBL " " \
    --field="\n":LBL " " \
    --field="$(gettext "Checks for new episodes at startup")":CHK "$update" \
    --field="$(gettext "Use this audio player")":LBL " " \
    --field="" "$altrau" \
    --field="$(gettext "Use this video player")":LBL " " \
    --field="" "$altrvi" \
    --field="$(gettext "Sync after update")":CHK "$sync" \
    --field="$(gettext "Sync only favorites")":CHK "$synf" \
    --field="$(gettext "Path where episodes should be synced")":LBL " " \
    --field="":DIR "$path" \
    --field="$(gettext "Synchronize")":FBTN "$DSP/podcasts.sh 'sync' 2" \
    --button="$(gettext "Remove")":"$DSP/cnfg.sh 'delete_all'" \
    --button="$(gettext "Cancel")":1 \
    --button="$(gettext "Save")":0)"
    ret=$?
    if [ $ret -eq 0 ]; then apply; fi
    cleanups "$DT/cp.lock"
    exit
}

function podmode() {
    nmfile() { echo -n "${1}" |md5sum |rev |cut -c 4- |rev; }
    function _list_1() {
        while read -r list1; do
            if [ -e "$DMP/cache/$(nmfile "$list1").png" ]; then
                echo "$DMP/cache/$(nmfile "$list1").png"
            else 
                echo "$DS_a/Podcasts/images/audio.png"; fi
            echo "$list1"
        done < "$DCP/1.lst"
    }
    function _list_2() {
        while read -r list2; do
            if [ -e "$DMP/cache/$(nmfile "$list2").png" ]; then
                echo "$DMP/cache/$(nmfile "$list2").png"
            else
            echo "$DS_a/Podcasts/images/audio.png"; fi
            echo "$list2"
        done < "$DCP/2.lst"
    }

    nt="$DCP/info"
    fdit=$(mktemp "$DT/fdit.XXXXXX")
    c=$(echo $(($RANDOM%100000))); KEY=$c
    if [ -d "$DT"/*.dl_poddir ]; then
        info="$(gettext "Downloading new episodes...")"
    elif [ -e ${updt} ]; then
        info="$(gettext "Checking for new episodes...")"
    else
        info="$(gettext "Podcasts")"
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
    --tab=" $(gettext "Episodes") " \
    --tab=" $(gettext "Favorites") " \
    --tab=" $(gettext "Note") " \
    --button="$(gettext "Play")":"$DS/play.sh play_list" \
    --button="$(gettext "Update")":2 \
    --button="$(gettext "Close")"!'window-close':1
    ret=$?
    note_mod="$(< "${fdit}")"
    if [ "${note_mod}" != "$(< "${nt}")" ]; then
        if ! grep '^$' < <(sed -n '1p' "${fdit}")
        then echo -e "\n${note_mod}" > "${nt}"
        else echo "${note_mod}" > "${nt}"; fi
    fi
    if [ $ret -eq 2 ]; then "$DSP/podcasts.sh" update 1; fi
    cleanups "${fdit}"
} 

function update() {
    include "$DS/ifs/mods/add"
    sets=( 'channel' 'link' 'logo' 'ntype' 'nmedia' 'ntitle' 'nsumm' 'nimage' 'url' )

    conditions() {
        if ps -A |pgrep -f "podcasts.sh set_channel"; then
            for s in {1..60}; do
                if ps -A |pgrep -f "podcasts.sh set_channel"; then
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
        if [ -e "$DCP/1.lst" ] && [[ $(wc -l < "$DCP/1.lst") \
        != $(wc -l < "$DCP/.1.lst") ]]; then
            cp "$DCP/.1.lst" "$DCP/1.lst"
        fi
        if [[ "$(< "$DCP/stts")" != 11 ]]; then
            echo 11 > "$DCP/stts"
        fi
        check_dir "$DM_tl/Podcasts/cache" "$DM_tl/Podcasts/.conf"
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
        if echo "$1" |grep -q ".mp3"; then ex=mp3; tp=aud
        elif echo "$1" |grep -q ".mp4"; then ex=mp4; tp=vid
        elif echo "$1" |grep -q ".ogg"; then ex=ogg; tp=aud
        elif echo "$1" |grep -q ".m4v"; then ex=m4v; tp=vid
        elif echo "$1" |grep -q ".mov"; then ex=mov; tp=vid
        elif echo "$1" |grep -o ".pdf"; then ex=pdf; tp=txt
        export ex tp
        else
        echo -e "$(gettext "Could not add some podcasts:")\n$FEED" >> "$DM_tl/Podcasts/.conf/feed.err"
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
    
    fetch_podcasts() {
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
                    if [ -z "${nmedia}" ]; then
                        echo -e "  -- no-media! $FEED\n"
                        > "$DCP/${ln}.rss"
                        echo -e "$(gettext "Please, reconfigure this feed:")\n$FEED" >> "$DCP/feed.err"
                        continue
                    fi
                    if [ "$ntype" = 1 ]; then
                        curl "${FEED}" > "$DT/out.xml"
                        if grep '^$' "$DT/out.xml"; then
                            sed -i '/^$/d' "$DT/out.xml"
                        fi
                        podcast_items="$(xsltproc "$DS/default/tmpl2.xml" "$DT/out.xml")"
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
                                    eyeD3 --encoding=$eyed3_encoding -t "${title}" \
                                    -a "${channel}" -A "Podcasts" "$DMC/$fname.$ex"
                                    mkhtml
                                    if [[ -s "$DCP/1.lst" ]]; then
                                        sed -i -e "1i${title}\\" "$DCP/1.lst"
                                    else 
                                        echo "${title}" > "$DCP/1.lst"
                                    fi
                                    
                                    [ $tp = aud ] && lbltp="$(gettext "Listen:")"
                                    [ $tp = vid ] && lbltp="$(gettext "Watch:")"
                                    ttitle="$(sed 's/\$/\\$/g' <<< "$title")"
                                    taskItem="$lbltp ${ttitle}"
                                    [  $(wc -c <<< $ttitle) -gt 60 ] && \
                                    taskItem="$lbltp ${ttitle:0:60}..."
                                    if ! grep -Fxq "${taskItem}" "$DC_a/Podcasts.tasks" >/dev/null 2>&1; then
                                        echo "${taskItem}" >> "$DC_a/Podcasts.tasks"
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
                                    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Podcasts/$date.updt"
                                fi
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
    if [[ ${2} = 1 ]]; then echo "Podcasts" > "$DC_s/tpa"; fi
    rm "$DM_tl/Podcasts"/*.updt
    > "$updt"
    echo -e "$(gettext "Updating")
    \r$(gettext "Latest downloads:") 0" \
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

    echo -e "$(gettext "Last update:") $(date "+%r %a %d %B")
    \r$(gettext "Latest downloads:") $new_episodes" \
    |sed -e 's/^[ \t]*//' |tr -d '\n' > "$DM_tl/Podcasts/$date.updt"

    idiomind tasks
    if [[ ${new_episodes} -gt 0 ]]; then
        if [[ ${new_episodes} -eq 1 ]]; then
            notify-send -i idiomind "$(gettext "Podcasts: New content")" \
            "$(gettext "1 episode downloaded")" -t 8000
        elif [[ ${new_episodes} -gt 1 ]]; then
            notify-send -i idiomind "$(gettext "Podcasts: New content")" \
            "$(gettext "$new_episodes episodes downloaded")" -t 8000
        fi
        if [ $(cat "$DC_a/Podcasts.tasks" |wc -l) -gt 8 ]; then
            awk '!x[$0]++' "$DC_a/Podcasts.tasks" |tail -n 8 > "$DT/Podcasts.tasks"
            mv -f "$DT/Podcasts.tasks" "$DC_a/Podcasts.tasks"
        fi
        removes
    else
        if [[ ${2} = 1 ]]; then
            notify-send -i idiomind \
            "$(gettext "Podcasts: Update finished")" \
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
    sz=(760 480); [[ ${swind} = TRUE ]] && sz=(540 300)
    dir="$DM_tl/Podcasts/cache"
    fname=$(echo -n "${item}" | md5sum | rev | cut -c 4- | rev)
    channel="$(grep -o channel=\"[^\"]* "$dir/${fname}.item" |grep -o '[^"]*$')"
    if grep -Fxo "${item}" "$DM_tl/Podcasts/.conf/2.lst"; then
        btnlabel="!list-remove!$(gettext "Remove from favorites")"
        btncmd="$DSP/cnfg.sh 'remove_item'"
    else
        btnlabel="!emblem-favorite!$(gettext "Add to favorites")"
        btncmd="'$DSP/podcasts.sh' new_item"
    fi
    btncmd2="'$DSP/podcasts.sh' save_as"
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
    internet
    if [[ -z "${2}" ]]; then
    cleanups "$DCP/${3}.rss"; exit 1; fi
    feed="${2}"
    num="${3}"
    # head
    feed_dest="$(curl -Ls -o /dev/null -w %{url_effective} "${feed}")"
    curl "${feed_dest}" |sed '1{/^$/d}' > "$DT/rss.xml"
    xml="$(xsltproc "$DS/default/tmpl1.xml" "$DT/rss.xml")"
    xml="$(echo -e "${xml}" |sed -e 's/^[ \t]*//' |tr -d '\n')"
    items1="$(echo "${xml}"  |tr '\n' ' ' \
    | tr -s '[:space:]' |sed 's/EOL/\n/g' |sed -r 's|-\!-|\n|g')"
    # content
    xml="$(xsltproc "$DS/default/tmpl2.xml" "$DT/rss.xml")"
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
    ftype1() {
        n=1
        while read -r get; do
            [[ ${n} = 3 || ${n} = 5 || ${n} = 6 ]] && continue
            if [ -n "$(grep -o -E '\.mp3|\.mp4|\.ogg|\.avi|\.m4v|\.mov|\.flv' <<< "${get}")" -a -z "${media}" ]; then
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
            if [ -n "$(grep -o -E '\.jpg|\.jpeg|\.png' <<< "${get}")" -a -z "${image}" ]
            then image="$n"; type=2; break; fi
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
    ftype1
    if [ -z "$sum2" ]; then
        summary="${sum1}"
    else
        summary="${sum2}"
    fi
    if [[ -z "${title}" ]] || [[ -z "${media}" ]] || [[ -z "${feed_dest}" ]]; then
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
 
function disc_podscats() {
    [ "$tlng" = English ] && src="\"podcasts learning English\" OR \"$(gettext "podcasts learning English")\""
    [ "$tlng" = French ] && src="\"podcasts learning French\" OR \"$(gettext "podcasts to learn French")\""
    [ "$tlng" = German ] && src="\"podcasts learning German\" OR \"$(gettext "podcasts to learn German")\""
    [ "$tlng" = Chinese ] && src="\"podcasts learning Chinese\" OR \"$(gettext "podcasts to learn Chinese")\""
    [ "$tlng" = Italian ] && src="\"podcasts learning Italian\" OR \"$(gettext "podcasts to learn Italian")\""
    [ "$tlng" = Japanese ] && src="\"podcasts learning Japanese\" OR \"$(gettext "podcasts to learn Japanese")\""
    [ "$tlng" = Portuguese ] && src="\"podcasts learning Portuguese\" OR \"$(gettext "podcasts to learn Portuguese")\""
    [ "$tlng" = Spanish ] && src="\"podcasts learning Spanish\" OR \"$(gettext "podcasts to learn Spanish")\""
    [ "$tlng" = Vietnamese ] && src="\"podcasts learning Vietnamese\" OR \"$(gettext "podcasts to learn Vietnamese")\""
    [ "$tlng" = Russian ] && src="\"podcasts learning Russian\" OR \"$(gettext "podcasts to learn Russian")\""
    xdg-open https://www.google.com/search?q="$src"

} >/dev/null 2>&1


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
        "$DS/ifs/mods/chng/podcasts.sh"
    else
        export item
        vwr
    fi
} >/dev/null 2>&1


function new_item() {
    DMC="$DM_tl/Podcasts/cache"
    DCP="$DM_tl/Podcasts/.conf"
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
    --window-icon=idiomind --center --on-top \
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
    set_channel)
    set_channel "$@" ;;
    sync)
    sync "$@" ;;
    disc_podscats)
    disc_podscats ;;
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

