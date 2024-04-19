#!/usr/bin/env bash

function log {
    echo -e "\e[34m[LOG]\e[0m $1"
}

function warn {
    echo -e "\e[33m[WARN]\e[0m $1"
}

function error {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

function success {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}