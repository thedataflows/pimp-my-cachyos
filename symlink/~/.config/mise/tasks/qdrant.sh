#!/bin/env bash

docker run -p 6333:6333 -p 6334:6334 -v "/mnt/linux2/dev/ai-storage/qdrant_storage:/qdrant/storage:z" qdrant/qdrant:latest
