#!/bin/env bash

CONTAINER_NAME=qdrant

CONTAINER_STATE_CMD="docker ps --all --format json | jq -r 'select(.Names==\"$CONTAINER_NAME\").State'"
CONTAINER_STATE=$(eval $CONTAINER_STATE_CMD)
if [[ -n "$CONTAINER_STATE" ]]; then
  if [[ "$CONTAINER_STATE" != "running" ]]; then
    set -x
    docker start "$CONTAINER_NAME"
    { set +x; } &>/dev/null
  fi
  CONTAINER_STATE=$(eval $CONTAINER_STATE_CMD)
  echo $CONTAINER_NAME $CONTAINER_STATE
  exit 0
fi

set -x
docker run -d --name "$CONTAINER_NAME" -p 6333:6333 -p 6334:6334 -v "/mnt/linux2/dev/ai-storage/qdrant_storage:/qdrant/storage:z" qdrant/qdrant:latest
sleep 1
echo $CONTAINER_NAME $CONTAINER_STATE
