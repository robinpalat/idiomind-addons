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

        python <<PY
import os, re, sqlite3, sys
logfile = os.environ['logfile']
errfilew = os.environ['errfilew']
lblerr = os.environ['lblerr']
datafilea = os.environ['datafilea']
datafileb = os.environ['datafileb']
datafilew = open(datafileb, "a")
indexfile = os.environ['indexfile']
indexfile = open(indexfile, "a")
tpcdb = os.environ['tpcdb']
db = sqlite3.connect(tpcdb)
db.text_factory = str
cur = db.cursor()
words = db.execute("select list from words")
words = words.fetchall()
wcount = len(words)
loglist = [line.strip() for line in open(logfile)]
for red in loglist:
    with open(datafilea,'r') as f:
        itema = [line for line in f if 'trgt{'+red+'}' in line]
    with open(datafileb,'r') as f:
        itemb = [line for line in f if 'trgt{'+red+'}' in line]
    if not itemb:
        if wcount < 201:
            item = itema[0].replace('}', '}\n')
            fields = re.split('\n',item)
            trgt = (fields[0].split('trgt{'))[1].split('}')[0]
            srce = (fields[1].split('srce{'))[1].split('}')[0]
            cur.execute("insert into words (list) values (?)", (trgt,))
            cur.execute("insert into learning (list) values (?)", (trgt,))
            indexfile.write("<span color='#AE3259'>"+trgt+"</span>\nFALSE\n"+srce+"\n")
            datafilew.write(itema[0]+"\n")
        else:
            with open(errfilew, "a") as f:
                f.write(lblerr+"\n"+red+"\n\n")
        wcount += 1
db.commit()
db.close()
indexfile.close()
datafilew.close()
PY

    touch "${DM_tl}/${name}"
    fi
}

( if [[ ${stts} -ge ${stts_d} ]] && [[ "${pr}" != e ]] && [[ "${act}" = TRUE ]]; then
    if [[ "${hard}" -gt 0 ]]; then
        sleep 1; addwords
    fi
fi ) &
