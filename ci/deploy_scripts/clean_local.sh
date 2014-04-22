#!/bin/bash
set -x

FUSE_PATH="/data/software/redhat/FUSE/fuse_full/jboss-fuse-6.1.0.redhat-379"

kill -kill $( ps aux | grep java | grep karaf | grep -v grep | awk '{ print $2; }' )

rm -rf "$FUSE_PATH/data" "$FUSE_PATH/instances"