#!/bin/bash

FABRIC_DIR="$(
    cd -- "$(dirname "$0")" >/dev/null 2>&1
    pwd -P
)/../.."
cd "$FABRIC_DIR"

rm -rf "$FABRIC_DIR/.generated"
