#!/usr/bin/env bash

### ARGS
quiet=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--environment) environment="$2"; shift ;;
        -m|--mappings) mappings="$2"; shift ;;
        -c|--command) command="$2"; shift ;;
        -q|--quiet) quiet=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$environment" ] || [ -z "$command" ]; then
    echo "Usage: $0 -e|--environment <environment> -c|--command <command> -m|--mappings <mappings?>"
    exit 1
fi
### ARGS

### FUNCTIONS
log() {
    if [[ "$quiet" == false ]]; then
        echo "$@"
    fi
}
run_command() {
    if [[ "$quiet" == true ]]; then
        "$@" > /dev/null 2>&1
    else
        "$@"
    fi
}
### FUNCTIONS

project=$(printf '%06x' $((RANDOM * RANDOM)))


log "Building..."
log "-----------------------------------------------"
log ""


run_command docker compose -p $project build


log ""
log "Starting the container..."
log "-----------------------------------------------"
log ""


run_command docker compose -p $project up $environment -d
CONTAINER=$(docker ps -alq)


log ""
log "Providing the input..."
log "-----------------------------------------------"
log ""


if [ -n "$mappings" ]; then
    jq -c '.inputs[]' $mappings | while read -r file; do
        source=$(echo "$file" | jq -r '.from')
        destination=$(echo "$file" | jq -r '.to')
        run_command docker compose -p $project cp "$source" "$environment:$destination"
    done
fi


log ""
log ""
log "Running your command: '$command' (in $environment)"
log "-----------------------------------------------"
log ""


docker exec -it $CONTAINER sh -c "$command"


log ""
log "Retrieving the output..."
log "-----------------------------------------------"
log ""


if [ -n "$mappings" ]; then
    jq -c '.outputs[]' $mappings | while read -r file; do
        source=$(echo "$file" | jq -r '.from')
        destination=$(echo "$file" | jq -r '.to')
        run_command docker compose -p $project cp "$environment:$source" "$destination"
    done
fi


log ""
log ""
log "-----------------------------------------------"
log "Stopping..."
log ""


run_command docker compose -p $project down $environment


log "Done in $SECONDS seconds!"