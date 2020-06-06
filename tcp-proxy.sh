#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "usage: $(basename $0) localPort destHost destPort"
    exit 1
fi

LOCAL_PORT="$1"
DEST_HOST="$2"
DEST_PORT="$3"

echo "Relay TCP/IP connections on localhost port: ${LOCAL_PORT} to ${DEST_HOST}:${DEST_PORT}"
socat TCP-LISTEN:${LOCAL_PORT},fork,reuseaddr TCP:${DEST_HOST}:${DEST_PORT}
