#!/bin/bash -xe
# shel-scripts/global_setup.sh
#
# Executes all the commands tha must be run on any job
#

rm -rf "$WORKSPACE/tmp"
mkdir -p "$WORKSPACE/tmp"
