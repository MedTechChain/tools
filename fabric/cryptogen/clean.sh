#!/bin/bash

FABRIC_FOLDER_PATH="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)/.."
cd "$FABRIC_FOLDER_PATH"

rm -rf "$FABRIC_FOLDER_PATH/.generated/cryptogen"
