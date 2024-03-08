#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 && pwd -P)"
cd "$SCRIPT_DIR"

FABRIC_DIR="$SCRIPT_DIR"

# load configuration
source "$FABRIC_DIR/.env"
export FABRIC_IMAGE_TAG

cd "$FABRIC_DIR/scripts"
./tools-cmd.sh bash
