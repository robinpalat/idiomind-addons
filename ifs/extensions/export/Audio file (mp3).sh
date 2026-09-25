#!/bin/bash

source /usr/share/idiomind/default/c.conf
source "$DS/ifs/cmns.sh"
rword="$(cdb "${tpcdb}" 1 config rword)"
autr="$(cdb "${cfgdb}" 1 user autr)"
mkdir -p "$DT/export_audio/a"
dire="$DT/export_audio"
s1="$DS/addons/Save as audio/si1.mp3"
s2="$DS/addons/Save as audio/si2.mp3"
so1="$DS/addons/Save as audio/si0_1.mp3"
so2="$DS/addons/Save as audio/si0_2.mp3"
s4="$DS/addons/Save as audio/si4.mp3"
img="$DS/addons/Save as audio/$tlng.png"
cd "${dire}"/


extchk () {
    msg "$(gettext "Something unexpected happened, exiting.")\n)" \
    error "$(gettext "Information")" 
    cleanups "$DT/export_audio" & exit 1
}

n=1
while read -r _item; do
    [ ! -d "$DT/export_audio" ] && break
    unset cdid trgt ; get_item "${_item}"
    
    if [ -n "${trgt}" -a -n "${cdid}" ]; then
    
        echo -n "${trgt}" >> "${dire}/text"
        
        if [ "${type}" = 2 ]; then
        
            if [ -f "${DM_tlt}/$cdid.mp3" ]; then
                sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; fi
            fi

        elif [ "${type}" = 1 ]; then
        
            if [ -f "$DM_tls/audio/${trgt,,}.mp3" ]; then
                sox "$DM_tls/audio/${trgt,,}.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; fi
                
            elif [ -f "${DM_tlt}/$cdid.mp3" ]; then
            
                sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; fi
            fi
        fi
    fi
    
    let n++

done < "${DC_tlt}/data"

mp3wrap ./a/"0album.mp3" $(ls -v ./*.mp3)
if [ $? != 0 ]; then extchk; fi
rm ./*.mp3;

n=1; a=1
while read -r _item; do
    [ ! -d "$DT/export_audio" ] && break
    unset cdid trgt ; get_item "${_item}"
    if [ -n "${trgt}" -a -n "${cdid}" ]; then
    
        echo -n "${trgt}" >> "${dire}/text"
        
        if [ "${type}" = 2 ]; then
        
            if [ -f "${DM_tlt}/$cdid.mp3" ]; then
            
                sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
                
                if [ "$rword" = 2 ]; then 
                
                    cp "$so2" "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                    
                    sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                fi
                
                cp "$s2" "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
                
                cp "$s4" "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
            fi

        elif [ "${type}" = 1 ]; then
        
            if [ -f "$DM_tls/audio/${trgt,,}.mp3" ]; then
            
                sox "$DM_tls/audio/${trgt,,}.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
                
                if [ "$rword" = 1 ]; then
                    sox "$DM_tls/audio/${trgt,,}.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                    
                    cp "$so1" "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                    
                    sox "$DM_tls/audio/${trgt,,}.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                fi
                    cp "$s1" "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                    
                    cp "$s4" "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi

            elif [ -f "${DM_tlt}/$cdid.mp3" ]; then
            
                sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
                
                if [ "$rword" = 1 ]; then 
                    sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                    
                    cp "$so1" "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                    
                    sox "${DM_tlt}/$cdid.mp3" -r 44100 -C 128 "$dire/$n.mp3"
                    if [ $? != 0 ]; then extchk; else let n++; fi
                fi
            
                cp "$s1" "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
                    
                cp "$s4" "$dire/$n.mp3"
                if [ $? != 0 ]; then extchk; else let n++; fi
            fi
        fi
    fi
    
    mp3wrap ./a/${a}album.mp3 $(ls -v ./*.mp3)
    if [ $? != 0 ]; then extchk; fi
    rm ./*.mp3; let a++; n=1
    
done < "${DC_tlt}/data"

#sox --combine sequence $(ls ./*.mp3) album_MP3WRAP.mp3
mp3wrap ./album.mp3 $(ls -v ./a/*.mp3)
if [ $? != 0 ]; then extchk; fi

[ -z "$autr" ] && autr="User"
if [ -f "$dire/text" ]; then
    eyeD3 --encoding=utf8 --add-lyrics "$dire/text":LYRICS_FILE:eng ./"album_MP3WRAP.mp3"
fi
eyeD3 --encoding=utf8 -t "$tpc" -a "$autr" -A "Idiomind" -n "1" ./"album_MP3WRAP.mp3" 
if [ -f "$img" ]; then
    eyeD3 --encoding=utf8 --remove-all-comments --add-image "$img":FRONT_COVER ./"album_MP3WRAP.mp3"
else
    eyeD3 --encoding=utf8 --remove-all-comments ./"album_MP3WRAP.mp3"
fi

if [ -e ./"album_MP3WRAP.mp3" ]; then 
    mv -f ./"album_MP3WRAP.mp3" "${1}.mp3"
else
    extchk
fi
cleanups "$DT/export_audio"

exit 0


