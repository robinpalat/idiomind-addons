#!/bin/bash
# -*- ENCODING: UTF-8 -*-

[ ! -f "$DC_a/whtr.cfg" ] && touch "$DC_a/whtr.cfg"
act=$(grep -o act=\"[^\"]* "$DC_a/whtr.cfg" |grep -o '[^"]*$')

function addwords() {
    local name
    name="$(grep -o name=\"[^\"]* "$DC_a/whtr.cfg" |grep -o '[^"]*$')"
    name="${name^}"
    if [ -z "$name" ]; then return; fi

    if [ ! -d "${DM_tl}/${name}" ]; then
        "$DS/add.sh" new_topic 1 0 "${name}"
    fi
    
    if [ -d "${DM_tl}/${name}/.conf" -a "${name}" != "${tpc}" ]; then
        export datafilea="${DC_tlt}/data"
        export logfile="${DC_tlt}/practice/log3"
        export datafileb="${DM_tl}/${name}/.conf/data"
        export indexfile="${DM_tl}/${name}/.conf/index"
        export tpcdb="${DM_tl}/${name}/.conf/tpc"
        export errfilew="${DM_tl}/${name}/.conf/note.err"
        export lblerr=$(gettext "Maximum number of notes has been exceeded:")

        {
            printf 'BEGIN TRANSACTION;\n'

            wcount="$(sqlite3 "$tpcdb" "SELECT COUNT(*) FROM words;")"

            while IFS= read -r red || [ -n "$red" ]; do

                red="$(printf '%s' "$red" |
                    sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

                [ -n "$red" ] || continue

                # Buscar la nota correspondiente en el tópico actual.
                itema="$(grep -F -m 1 "trgt{$red}" "$datafilea" || true)"

                [ -n "$itema" ] || continue

                # Comprobar si ya existe en el tópico destino.
                itemb="$(grep -F -m 1 "trgt{$red}" "$datafileb" || true)"

                [ -n "$itemb" ] && continue

                if [ "$wcount" -lt 201 ]; then

                    # Extraer trgt y srce.
                    trgt="$(sed -n 's/.*trgt{\([^}]*\)}.*/\1/p' <<< "$itema")"
                    srce="$(sed -n 's/.*srce{\([^}]*\)}.*/\1/p' <<< "$itema")"

                    [ -n "$trgt" ] || continue

                    # Escapar para SQLite.
                    trgt_sql="${trgt//\'/\'\'}"

                    printf "INSERT INTO words (list) VALUES ('%s');\n" \
                        "$trgt_sql"

                    printf "INSERT INTO learning (list) VALUES ('%s');\n" \
                        "$trgt_sql"

                    # Mantener exactamente el formato del index original.
                    printf "<span color='#AE3259'>%s</span>\nFALSE\n%s\n" \
                        "$trgt" "$srce" >> "$indexfile"

                    # Equivalente a datafilew.write(itema[0] + "\n")
                    printf '%s\n' "$itema" >> "$datafilew"

                    wcount=$((wcount + 1))

                else

                    printf '%s\n%s\n\n' "$lblerr" "$red" >> "$errfilew"

                    wcount=$((wcount + 1))

                fi

            done < "$logfile"

            printf 'COMMIT;\n'

        } | sqlite3 -bail "$tpcdb"

    touch "${DM_tl}/${name}"
    fi
}



( if [[ "$active_practice" != e ]] && [[ "$act" = TRUE ]]; then
    if [[ "$count_hard" -gt 0 ]]; then
        sleep 1; addwords
    fi
fi ) &
