#!/bin/bash
#
# BuZi - A debian system builder
# Copyright (C) 2012 Amir Hassan <amir@viel-zu.org>
#
# See LICENSE file
#


dir="`dirname $0`"
RUNIMAGE_DIR="`cd $dir; pwd`"

export BOOTSTRAP_LOG="runimage.log"
source "$RUNIMAGE_DIR/.functions.sh"

function doRunQemu() {
  check "Starting $1" \
    "true"
  $1 -soundhw ac97 -sdl -enable-kvm -hda $IMAGE_FILE -net user,hostfwd=tcp::5555-:80,hostfwd=tcp::5556-:22 -net nic -m 256
  exit $?
}

function printUsage() {
  cat 1>&2 <<EOUSAGE
runimage.sh - Run a disk image of the buzi system in qemu

Usage: $0 <image>
<image>           the disk image file
EOUSAGE
  exit 1
}

[ $# -ne 1 ] && printUsage

IMAGE_FILE="$1"

check "Exists image file $IMAGE_FILE" \
  "test -f $IMAGE_FILE"

which qemu > /dev/null && doRunQemu qemu
which qemu-system-`uname -i` > /dev/null && doRunQemu qemu-system-`uname -i`

check "Starting qemu" \ 
  "false"
