#!/usr/bin/env bash

networks=$(docker network ls --format '{{.ID}} {{.Name}}')

while read -r network_id network_name; do

  containers=$(docker network inspect --format '{{range .Containers}}{{.Name}} {{end}}' "$network_id")

  if [ ! -z "$containers" ]; then
      echo "$network_name:"
    for container in $containers; do
      echo "  $container"
    done
    echo
  fi
done <<< "$networks"
