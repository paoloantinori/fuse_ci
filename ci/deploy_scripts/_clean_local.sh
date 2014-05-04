#!/bin/bash

##########################################################################################################
# Description:
#
# helper script used to kill all the running instances of Fuse/Karaf and remove temporary files
#######################################################################################################

set -x

FUSE_PATH="/data/software/redhat/FUSE/fuse_full/jboss-fuse-6.1.0.redhat-*"

kill -kill $( ps aux | grep java | grep karaf | grep -v grep | awk '{ print $2; }' )

rm -rf "$FUSE_PATH/data" "$FUSE_PATH/instances"