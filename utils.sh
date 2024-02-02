#!/bin/bash

log () {
    echo "[$(date +"%H:%M:%S")]: $*"
}

check_exec() {
    if type $1 &> /dev/null; then
        log "$1 exists"
        return 0
    else
        log "$1 does not exist"
        return 1
    fi
}


check_vars() {
    for var_name in "$@"; do
        if [ -z "${!var_name}" ]; then
            log "Error: $var_name is not set or is empty"
            return 1
        else
            log "OK $var_name" 
        fi
    done
    return 0
}
