#!/bin/bash

SCRIPT_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
FABRIC_FOLDER_PATH="$SCRIPT_PATH/.."
GENERATED_FILES_PATH="$FABRIC_FOLDER_PATH/.generated"

./run_command.sh "cryptogen generate --config=crypto-config.yaml --output ./generated"