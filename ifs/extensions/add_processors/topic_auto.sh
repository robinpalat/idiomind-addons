#!/bin/bash
# -*- ENCODING: UTF-8 -*-

if [[ "$name" = "/auto" ]]; then
    "$DS/addons/Topic Builder/topic_builder.sh" start
    exit 0
fi
