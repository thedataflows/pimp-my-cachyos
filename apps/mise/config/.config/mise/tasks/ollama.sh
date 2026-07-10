#!/bin/env bash

CONTAINER_NAME=ollama

if [[ -n "$1" ]]; then
  set -x
  docker $1 $CONTAINER_NAME
  { set +x; } 2>/dev/null
  exit 0
fi

CONTAINER_STATE_CMD="docker ps --all --format json | jq -r 'select(.Names==\"$CONTAINER_NAME\").State'"
CONTAINER_STATE=$(eval $CONTAINER_STATE_CMD)
if [[ -n "$CONTAINER_STATE" ]]; then
  if [[ "$CONTAINER_STATE" != "running" ]]; then
    set -x
    docker start "$CONTAINER_NAME"
    { set +x; } &>/dev/null
  fi
  echo $CONTAINER_NAME $(eval $CONTAINER_STATE_CMD)
  exit 0
fi

set -x
docker run -d \
  --device /dev/kfd \
  --device /dev/dri \
  -v $HOME/.ollama:/root/.ollama \
  -p 11434:11434 \
  --name "$CONTAINER_NAME" \
  ollama/ollama:rocm
sleep 1
echo $CONTAINER_NAME $(eval $CONTAINER_STATE_CMD)
