#!/bin/bash
#
# BuZi - A debian system builder
# Copyright (C) 2012 Amir Hassan <amir@viel-zu.org>
#
# See LICENSE file
#

dir="`dirname $0`"
MAKEIMAGE_DIR="`cd $dir; pwd`"

export BOOTSTRAP_LOG="makeimage.log"

source "$MAKEIMAGE_DIR/.functions.sh"

function absDir() {
  dir="`dirname $1`"
  absdir="`cd $dir; pwd`"
  echo $absdir
}

function absPath() {
  dir="`dirname $1`"
  base="`basename $1`"
  absdir="`cd $dir; pwd`"
  echo $absdir/$base
}

function printUsage() {
  cat 1>&2 <<EOUSAGE
makeimage.sh - Prepare a disk image for installation of the buzi system.

Usage: $0 [-z][-c <chrootdir>][-s <sizeInM>] <target>
<target>	   the target location for the disk image

Options:
  -z               write zeroes to the device before creating the partition
  -s <sizeInM>	   overwrite the default (= 500MB) disk image size.
  -c <chrootdir>   after creating the disk image mount it in the specified directory
EOUSAGE
  exit 1
}

WRITE_ZEROES=
IMAGE_SIZE=500
IMAGE_FILE=
CHROOT_DIR=

while getopts 'zs:c:' c
do
  case $c in
    z) WRITE_ZEROES="YES";;
    s) IMAGE_SIZE="$OPTARG";;
    c) CHROOT_DIR="$OPTARG";;
    \?) printUsage;;
  esac
done

shift $(($OPTIND - 1))

[ $# -ne 1 ] && printUsage

IMAGE_FILE="`absPath $1`"
LOOPBACK_DEVICE=`losetup -f`
MAKESTICK_OPTS="-s $IMAGE_SIZE"
[ -n "$WRITE_ZEROES" ] && MAKESTICK_OPTS="$MAKESTICK_OPTS -z"

[ -n "$CHROOT_DIR" ] && check "Mountpoint $CHROOT_DIR is unused" \
  "! mountpoint -q $CHROOT_DIR"

check "Creating disk image file $IMAGE_FILE of size $IMAGE_SIZE MB" \
  "dd if=/dev/zero of=$IMAGE_FILE bs=1M count=1 seek=$[ $IMAGE_SIZE - 1 ] > /dev/null"

check "Setting up disk image file on loopback device $LOOPBACK_DEVICE" \
  "losetup $LOOPBACK_DEVICE $IMAGE_FILE"


./makestick.sh $MAKESTICK_OPTS "$LOOPBACK_DEVICE"
check "Run makestick.sh $MAKESTICK_OPTS $LOOPBACK_DEVICE" \
          "[ $? -eq 0 ]"

OFFSET=`parted -s -m $LOOPBACK_DEVICE unit B print | grep "^1:" | cut -f 2 -d ":" | tr B ' '`

check "Read partition offset" \
  "[ $? -eq 0 ]"
  
check "Sync" \
  "sync"

check "Detaching disk image file" \
  "losetup -d $LOOPBACK_DEVICE"

[ -n "$CHROOT_DIR" ] && check "Mounting screen invader partition on $CHROOT_DIR" \
  "mount $IMAGE_FILE $CHROOT_DIR -o loop,offset=$OFFSET"

exit 0

