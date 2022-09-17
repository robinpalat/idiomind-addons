#!/bin/bash
# -*- ENCODING: UTF-8 -*-

file_cfg="${DM_tl}/Podcasts/.conf/podcasts.cfg"
aname='Podcasts'
if [[ $(wc -l < "$file_cfg") = 8 ]]; then
declare -A items=( ['Videos']='evideo' ['New episodes']='eaudio' ['Favorites']='ekeep')
fi
