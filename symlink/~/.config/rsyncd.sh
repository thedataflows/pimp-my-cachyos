#!/bin/env bash

set -x
sudo rsync --daemon --config ${0%/*}/rsyncd.conf --no-detach --verbose
