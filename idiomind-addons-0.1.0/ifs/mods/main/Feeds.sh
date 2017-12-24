#!/bin/bash
# -*- ENCODING: UTF-8 -*-

export tpc="Feeds"
function Feeds() {
/usr/share/idiomind/addons/Feeds/feeds.sh feedmode $1 & exit
}
