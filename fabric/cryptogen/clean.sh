#!/bin/bash

SCRIPT_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
FABRIC_FOLDER_PATH="$SCRIPT_PATH/.."
GENERATED_FILES_PATH="$FABRIC_FOLDER_PATH/.generated"

CONTAINER_NAME="cryptogen-generate"

rm -rf "$GENERATED_FILES_PATH/cryptogen"

docker rm "$CONTAINER_NAME" > /dev/null 2>&1