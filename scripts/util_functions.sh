#
# Copyright (C) 2019 by SaMad SegMane (svoboda18)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Util Functions Script v1.5 by svoboda18
#
# Usage:
# . ./util_functions.sh
#
# Intro:
#
# This script has a lot of functions used by almost all scripts on this tool, such as:
#  loads the configurations infos from config.prop
#  setup_flashable: prepares some VARS needed by other functions
#  ui_print: shows ui logs
#  log: store logs in <recovery.log>
#  ex: show a ui error log
#  get_flags: detects the values of KEEP** for current device
#  find_block: finding device blocks
#  mount_system: it mounts /system in rw mode
#  find_boot_image: it seach for boot partitons in different ways
#  convet_boot_image: converts boots partitions to a raw image
#  flash_image: flash $1 image at $2 partiton (location)
#  ....: ...
#
# Warning:
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses
#

# read the config before doing any thing
CONFIGFILE="$ZIPDIR/config.prop"
set -e

# Trim any lines starts with "#"
sed '/^#/d' -i "$CONFIGFILE"

# Start reading
echo "- Reading config file.."
# Only read valid lines thats are in .prop format
sed -r '/(^#|^.* = .*|^.*=.* .*|^.* .*=.*)/d;/(.*=.*)/!d' "$CONFIGFILE" | while read CONFIG
do
# slpit line into $VAR and it is VALUE
VAR=$(echo "$CONFIG" | cut -d= -f1)
VARVALUE=$(sed "s/$VAR=//p;d" "$CONFIGFILE")

# Export value (external scripts can use it)
export $VAR="$VARVALUE"
echo "  * "$VAR="$VARVALUE"
done
echo "- Reading config file done!."

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

fix_recovery() {
  mount -o bind /dev/urandom /dev/random
  # Temporarily block out all custom recovery binaries/libs
  mv /sbin /sbin_tmp
  # Unset library paths
  OLD_LD_LIB=$LD_LIBRARY_PATH
  OLD_LD_PRE=$LD_PRELOAD
  unset LD_LIBRARY_PATH
  unset LD_PRELOAD
}

unfix_recovery() {
  mv /sbin_tmp /sbin 2>/dev/null
  [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB
  [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE
}

fix_some() {
  [ -z $KEEPVERITY ] && KEEPVERITY=false
  [ -z $KEEPFORCEENCRYPT ] && KEEPFORCEENCRYPT=false
  for dir in $BOOTDIR $TMPDIR
  do
     cd $dir
     busybox chmod -R 755 .
  done
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
   # dynamicly print in gui
   echo -e "ui_print $1\n\nui_print" >> /proc/self/fd/$OUTFD
   sleep 0.1
}

log() {
   echo -n -e "$@\n"
}

ex() {
   ui_print "$@"
   fix_permissions
   unfix_recovery
   clean_all
   exit 1
}

backup() {
   # Keep any old backup then backup.
   [ -f "${1}.bak" ] && backup=$1.`date +%d-%b-%H-%M`.bak && busybox cp -f "$1" "$backup" || busybox cp -f "$1" "${1}.bak"
}

mount_parts() {
for PART in system vendor 
do
  # Mount system as rw
  log "- Mounting /$PART"
  [ -f /$PART/build.prop ] || is_mounted /$PART || mount -o rw /$PART 2>/dev/null
  if ! is_mounted /$PART && ! [ -f /$PART/build.prop ]; then
    PARTBLOCK=`find_block $PART$SLOT`
    mount -t ext4 -o rw $PARTBLOCK /$PART
  fi
  [ -f /$PART/build.prop ] || is_mounted /$PART || ex "! Cannot mount /$PART"
done
}

unmount_parts() {
for PART in system vendor dev/random 
do
  # Unmount $PART
  log "- Unmounting /$PART"
  if ! is_mounted /$PART; then
    umount -l /$PART 2>/dev/null
  fi
done
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

setup_flashable() {
  # Required for ui_print to work correctly
  # Preserve environment varibles
  OLD_PATH=$PATH
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
   [ -f $TMPDIR/rawbootimage.img ] && BOOTIMAGEFILE="$TMPDIR/rawbootimage.img" && ui_print "   * Boot partition converted to rawbootimage.img" || ex "  ! Unable to convert boot image!"
}

flash_image() {
   busybox dd if="$1" of="$2" && ui_print "   * Sucessfuly flashed $1" || ex "   ! Unable to flash $1!"
}

# need to call it, thats all functions will work
setup_flashable