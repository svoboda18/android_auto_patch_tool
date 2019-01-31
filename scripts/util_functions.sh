#
# Copyright (C) 2019 by SaMad SegMane (svoboda18)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses
#

###############
#             #
#  FUNCTIONS  #
#             #
###############

toupper() {
  echo "$@" | tr '[:lower:]' '[:upper:]'
}

grep_prop() {
  # a recovery getprop()
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

grep_cmdline() {
  local REGEX="s/^$1=//p"
  cat /proc/cmdline | tr '[:space:]' '\n' | sed -n "$REGEX" 2>/dev/null
}

is_mounted() {
  cat /proc/mounts | grep -q " `readlink -f $1` " 2>/dev/null
  return $?
}

find_block() {
  # function for finding device blocks
  for BLOCK in "$@"; do
    DEVICE=`find /dev/block -type l -iname $BLOCK | head -n 1` 2>/dev/null
    if [ ! -z $DEVICE ]; then
      readlink -f $DEVICE
      return 0
    fi
  done
  # Fallback by parsing sysfs uevents
  for uevent in /sys/dev/block/*/uevent; do
    local DEVNAME=`grep_prop DEVNAME $uevent`
    local PARTNAME=`grep_prop PARTNAME $uevent`
    for p in "$@"; do
      if [ "`toupper $p`" = "`toupper $PARTNAME`" ]; then
        echo /dev/block/$DEVNAME
        return 0
      fi
    done
  done
  return 1
}

ui_print() {
   # Sleep for 0.7 then print in gui.
   sleep 0.7
   echo -e "ui_print $1\n\nui_print" >> /proc/self/fd/$OUTFD
}

log() {
   echo -n -e "$@\n"
}

ex() {
   ui_print "$@"
   exit 1
}

backup() {
   # Remove any old backup then backup.
   busybox rm -rf "${1}.bak"
   busybox echo $(cat "$1") >> "${1}.bak"
}

mount_system() {
   # Mount system as rw
  log "- Mounting /system"
  [ -f /system/build.prop ] || is_mounted /system || mount -o rw /system 2>/dev/null
  if ! is_mounted /system && ! [ -f /system/build.prop ]; then
    SYSTEMBLOCK=`find_block system$SLOT`
    mount -t ext4 -o rw $SYSTEMBLOCK /system
  fi
  [ -f /system/build.prop ] || is_mounted /system || ex "   ! Cannot mount /system"
  grep -qE '/dev/root|/system_root' /proc/mounts && SYSTEM_ROOT=true || SYSTEM_ROOT=false
  if [ -f /system/init ]; then
    SYSTEM_ROOT=true
    mkdir /system_root 2>/dev/null
    mount --move /system /system_root
    mount -o bind /system_root/system /system
  fi
}

get_flags() {
  # Get correct flags for dm-verity/forceencrypt patch
  # override variables
  KEEPVERITY=
  KEEPFORCEENCRYPT=
  if [ -z $KEEPVERITY ]; then
    if $SYSTEM_ROOT; then
      KEEPVERITY=true
    else
      KEEPVERITY=false
    fi
  fi
  if [ -z $KEEPFORCEENCRYPT ]; then
    grep ' /data ' /proc/mounts | grep -q 'dm-' && FDE=true || FDE=false
    [ -d /data/unencrypted ] && FBE=true || FBE=false
    # No data access means unable to decrypt in recovery
    if $FDE || $FBE || ! $DATA; then
      KEEPFORCEENCRYPT=true
    else
      KEEPFORCEENCRYPT=false
    fi
  fi
}

setup_bb() {
   # Make sure this path is in the front, and install bbx
   echo $PATH | grep -q "^$TMPDIR/bin" || export PATH=$TMPDIR/bin:$PATH
   $TMPDIR/bin/busybox --install -s $TMPDIR/bin
}

setup_flashable() {
  # Required for ui_print to work correctly
  # Preserve environment varibles
  OLD_PATH=$PATH
  setup_bb
  if [ -z $OUTFD ] || readlink /proc/$$/fd/$OUTFD | grep -q /tmp; then
    # We will have to manually find out OUTFD
    for FD in `ls /proc/$$/fd`; do
      if readlink /proc/$$/fd/$FD | grep -q pipe; then
        if ps | grep -v grep | grep -q " 3 $FD "; then
          OUTFD=$FD
          break
        fi
      fi
    done
  fi
}

find_boot_image() {
  # Find boot.img partition
  BOOTIMAGE=
  if [ ! -z $SLOT ]; then
    BOOTIMAGE=`find_block boot$SLOT ramdisk$SLOT`
  else
    BOOTIMAGE=`find_block boot ramdisk boot_a kern-a android_boot kernel lnx bootimg`
  fi
  if [ -z $BOOTIMAGE ]; then
    # Lets see what fstabs tells me
    BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
  fi
   [ ! -z $BOOTIMAGE ] && ui_print "   * Boot partition found at $BOOTIMAGE" || ex "   ! Unable to find boot partition!"
}

convert_boot_image() {
   # Convert to a raw boot.img, it required for devices with kitkat kernel and lower
   busybox dd if="$BOOTIMAGE" of="$TMPDIR/rawbootimage.img"
   [ -f /tmp/rawbootimage.img ] && BOOTIMAGEFILE="$TMPDIR/rawbootimage.img" && ui_print "   * Boot partition converted to rawbootimage.img" || ex "  ! Unable to convert boot image!"
}

flash_image() {
   busybox dd if=$1 of=$2 && ui_print "   * Sucessfuly flashed $1" || ex "   ! Unable to flash $1!"
}