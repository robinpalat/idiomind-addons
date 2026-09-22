#!/bin/bash
# -*- ENCODING: UTF-8 -*-

if [[ "$name" = "/auto" ]]; then
    "$DS/addons/AI Topic Builder/ai_topic_builder.sh" start
    exit 0
fi
