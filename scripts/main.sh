#!/sbin/sh

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
#  VARIABLES  #
#             #
###############

ver=0.5
ROOTDIR=/
TMPDIR=/tmp
PATCHDIR="$TMPDIR/fpatcher"
BOOTDIR="$TMPDIR/boot"
systemprop=/system/build.prop
bootprop="$TMPDIR/boot/default.prop"
buildprop="$TMPDIR/build.prop"
defaultprop="$TMPDIR/default.prop"

###############
#             #
#  FUNCTIONS  #
#             #
###############

# Load utility functions
cd $TMPDIR
. ./util_functions.sh
cd $ROOTDIR

clean_all() {
  unfix_recovery
  umount -l /system_root 2>/dev/null
  umount -l /system 2>/dev/null
  umount -l /vendor 2>/dev/null
  umount -l /dev/random 2>/dev/null
  # Clean /tmp
  busybox rm -rf "$TMPDIR/*.img"
  busybox rm -rf "$TMPDIR/*.prop"
  busybox rm -rf "$TMPDIR/boot"
  busybox rm -rf "$TMPDIR/*.sh"
}

fix_permissions() {
   # Restore the old path, required since chmod,chown wont work without it
   export PATH="$OLD_PATH"

   # fix permissions for all in /system
   sleep 0.5
   # /system
   log "fixing permissions for /system"
   busybox chown 0.0 /system
   busybox chown 0.0 /system/*
   busybox chown 0.2000 /system/bin
   busybox chown 0.2000 /system/vendor
   busybox chown 0.2000 /system/xbin
   busybox chmod 755 /system/*
   find /system -type f -maxdepth 1 -exec busybox chmod 644 {} \;

  # /system/cameradata
   if [ -d "/system/cameradata" ]; then
   log "fixing permissions for /system/cameradata"
   busybox chown -R 0.0 /system/cameradata
   find /system/cameradata \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi

   # /system/bin
   log "fixing permissions for /system/bin"
   busybox chmod 755 /system/bin/*
   busybox chown 0.2000 /system/bin/*
   busybox chown -h 0.2000 /system/bin/*
   busybox chown 0.0 /system/bin/log /system/bin/ping
   busybox chmod 777 /system/bin/log

   # /system/csc
   if [ -d "/system/csc" ]; then
   log "fixing permissions for /system/csc"
   busybox chown -R 0.0 /system/csc
   find /system/csc \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi

   # /system/etc
   log "fixing permissions for /system/etc"
   busybox chown -R 0.0 /system/etc
   find /system/etc \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   busybox chown 1014.2000 /system/etc/dhcpcd/dhcpcd-run-hooks
   busybox chmod 550 /system/etc/dhcpcd/dhcpcd-run-hooks
   [ -d "/system/init.d" ] && busybox chmod 755 /system/etc/init.d/*

   # /system/finder_cp
   if [ -d "/system/finder_cp" ]; then
   log "fixing permissions for /system/      finder_cp"
   busybox chown 0.0 /system/fnder_cp/*
   busybox chmod 644 /system/finder_cp/*
   fi

   # /system/fonts
   log "fixing permissions for /system/fonts"
   busybox chown 0.0 /system/fonts/*
   busybox chmod 644 /system/fonts/*
   
   # /system/lib
   log "fixing permissions for /system/lib"
   busybox chown -R 0:0 /system/lib
   find /system/lib \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)

   # /system/lib64
   if [ -d "/system/lib64" ]; then
   log "fixing permissions for /system/lib64"
   busybox chown -R 0:0 /system/lib64
   find /system/lib64 \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi

   # /system/media
   log "fixing permissions for /system/media"
   busybox chown -R 0:0 /system/media
   find /system/media \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)

   # /system/sipdb
   if [ -d "/system/sipdb" ]; then
   log "fixing permissions for /system/sipdb"
   busybox chown 0.0 /system/sipdb/*
   busybox chmod 655 /system/sipdb/*
   fi

   # /system/tts
   if [ -d "/system/tts" ]; then
   log "fixing permissions for /system/tts"
   busybox chown -R 0:0 /system/tts
   find /system/tts \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi

   # /system/usr
   log "fixing permissions for /system/usr"
   busybox chown -R 0:0 /system/usr
   find /system/usr \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)

   # /system/vendor
   log "fixing permissions for /system/vendor"
   find /system/vendor \( -type d -exec    busybox chown 0.2000 {} + \) -o \( -type f -exec    busybox chown 0.0 {} + \)
   find /system/vendor \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)

   # /system/voicebargeindata
   if [ -d "/system/voicebargeindata" ]; then
   log "fixing permissions for /system/voicebargeindata"
   busybox chown -R 0:0 /system/voicebargeindata
   find /system/voicebargeindata \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi

   # /system/vold
   if [ -d "/system/vold" ]; then
   log "fixing permissions for /system/vold"
   busybox chown 0.0 /system/vold/*
   busybox chmod 644 /system/vold/*
   fi

   # /system/wallpaper
   if [ -d "/system/wallpaper" ]; then
   log "fixing permissions for /system/wakeupdata"
   busybox chown -R 0:0 /system/wakeupdata
   find /system/wakeupdata \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi

   # /system/wallpaper
   if [ -d "/system/wallpaper" ]; then
   log "fixing permissions for /system/wallpaper"
   busybox chown 0.0 /system/wallpaper/*
   busybox chmod 644 /system/wallpaper/*
   fi

   # /system/xbin
   log "fixing permissions for /system/xbin"
   busybox chmod 755 /system/xbin/*
   busybox chown 0.2000 /system/xbin/*
   busybox chown -h 0.2000 /system/xbin/*
   
   # /system/photoreader
   if [ -d "/system/photoreader" ]; then
   log "fixing permissions for /system/photoreader"
   busybox chown -R 0.2000 /system/photoreader/*
   find /system/photoreader/ \( -type d -exec busybox chmod 755 {} + \) -o \( -type f -exec busybox chmod 644 {} + \)
   fi
   ui_print "   * Fixed all permissions in /system"
}

change_power() {
FW=null
# Set some flags depending on what copied over
if [ -f $TMPDIR/power_profile.xml ]; then
  framework=1
  busybox mkdir -p $PATCHDIR/system/framework/framework-res.apk/res/xml/
  busybox cp $TMPDIR/power_profile.xml $PATCHDIR/system/framework/framework-res.apk/res/xml/
else
  framework=0
fi

# Prep things stemming from /system/framework
if [ "$framework" -eq "1" ]; then
  busybox mkdir -p $PATCHDIR/apply/system/framework
  log "Preparing /system/framework files"
  cd $PATCHDIR/system/framework
  f=framework-res.apk
  log "Processing $f"
  busybox cp /system/framework/$f $PATCHDIR/apply/system/framework/
    if [ -f "$PATCHDIR/apply/system/framework/$f" ]; then
      log "$f copied"
      FW="$f"
	else
	  log "Error copying $f"
	fi
  log "Done checking $f"
else
  log "No power_profile.xml file found"
fi

# Ok, before doing much else, we should zip up and move the
# flashable backup somewhere and name it something
if [ "$framework" -eq "1" ]; then
  ui_print "   - Backuping $f"
  log "Preparing backup flashable zip"
  if [ -d /sdcard/fwpatchundo ]; then
    log "Deleting old undo zip"
    busybox rm -rf /sdcard/fwpatchundo
  fi
  busybox mkdir -p /sdcard/fwpatchundo
  cd $PATCHDIR/apply/
  zip -r -9 /sdcard/fwpatchundo/UndoFwPatch.zip * || ui_print "   ! Unable to backup ${f}!"
else
  log "Nothing to backup... skipping"
fi

# Now to process the patches - /system/framework
if [ "$framework" -eq "1" ]; then
   ui_print "   - Adding power_profile.xml"
  cd $PATCHDIR/apply/system/framework
  f=framework-res.apk
  log "Working on $f"
  cd $PATCHDIR/system/framework/$f/
  zip -rn .png:.arsc:.ogg:.jpg:.wav $PATCHDIR/apply/system/framework/$f * || ex "   ! Unable to patch ${f}!"
  ui_print "   * Sucessfully patched ${f}"
  log "Patched $f"
fi

# Move each new app back to its original location
if [ "$framework" -eq "1" ]; then
  cd $PATCHDIR/apply/system/framework
  busybox rm -rf /system/framework/$FW
  busybox cp *.apk /system/framework/
fi
}

prop_append() {
# Set out files paramaters
tweak="$1"
build="$2"

# Check for backup
answer=$(busybox sed "s/BACKUP=//p;d" "$tweak")
case "$answer" in
        y|Y|yes|Yes|YES)
	    # Call backup function for system prop.
	    backup "$systemprop" ;;
	
        n|N|no|No|NO) ;;
        # Nothing
        
        *)
	    # Check if empty or invalid
	    [[ -z "$answer" || ! -d $(dirname "$answer") ]] && log "Given path is empty or parent directory does not exist" || backup "$answer" ;;
esac
sleep 2

# Required, since busybox sed wont work without it.
busybox echo "" >> $build

# Start appending
set -e
busybox sed -r '/(^#|^ *$|^BACKUP=)/d;/(.*=.*|^\!|^\@.*\|.*|^\$.*\|.*)/!d' "$tweak" | while read line
do
	# Remove entry
	if busybox echo "$line" | busybox grep -q '^\!'
	then
		entry=$(busybox echo "${line#?}" | busybox sed -e 's/[\/&]/\\&/g')
		# Remove from $build if present
		busybox grep -q "$entry" "$build" && (busybox sed "/$entry/d" -i "$build" && ui_print "   * All lines containing \"$entry\" removed")
	# Append string
	elif busybox echo "$line" | busybox grep -q '^\@'
	then
		entry=$(busybox echo "${line#?}" | busybox sed -e 's/[\/&]/\\&/g')
		var=$(busybox echo "$entry" | cut -d\| -f1)
		app=$(busybox echo "$entry" | cut -d\| -f2)
		# Append string to $var's value if present in $build
		busybox grep -q "$var" "$build" && (busybox sed "s/^$var=.*$/&$app/" -i "$build" && ui_print "   * \"$app\" Appended to value of \"$var\"")
	# Ahange value only if entry exists
	elif busybox echo "$line" | busybox grep -q '^\$'
	then
		entry=$(busybox echo "${line#?}" | busybox sed -e 's/[\/&]/\\&/g')
		var=$(busybox echo "$entry" | cut -d\| -f1)
		new=$(busybox echo "$entry" | cut -d\| -f2)
		# Change $var's value if $var present in $build
		busybox grep -q "$var=" "$build" && (busybox sed "s/^$var=.*$/$var=$new/" -i "$build" && ui_print "   * Value of \"$var\" changed to \"$new\"") 
	# Add or override entry
	else
		var=$(busybox echo "$line" | cut -d= -f1)
		# If variable already present in $build
		if busybox grep -q "$var" "$build"
		then
			# Override value in $build if different
			busybox grep -q $(busybox grep "$var" "$tweak") "$build" || (busybox sed "s/^$var=.*$/$line/" -i "$build" && ui_print "   * Value of \"$var\" overridden")
		# Else append entry to $build
		else
			busybox echo "$line" >> "$build" && ui_print "   * Entry \"$line\" added"
		fi
	fi
done
# Trim empty and duplicate lines of $build
busybox sed '/^ *$/d' -i "$build"
}

patch_ramdisk() {
fix_some
script=patch.sh

# Mouve cpio for changing.
mv ramdisk.cpio $BOOTDIR/ramdisk.cpio
cd $BOOTDIR

# Check if default.prop found, add it if not then append.
ui_print "  - Adding Default.prop changes..."
if [ -f default.prop ]; then
    chmod 777 default.prop
    prop_append "$defaultprop" "$bootprop"
elif [ ! -f default.prop ]; then
    boot --cpio ramdisk.cpio \
    "extract default.prop default.prop"
    chmod 777 default.prop
    prop_append "$defaultprop" "$bootprop"
fi

# Start making a script to add all .rc at once, required since it will bootloop without it.
busybox echo "boot --cpio ramdisk.cpio \\" >> $script

# Check if folder is empty from .rc files or not
if [[ "$(busybox ls *.rc)" != *"rc"* ]] || [[ "$(busybox ls *.sh)" != *"sh"* ]]; then
   ui_print "  ! Boot folder empty, skipping .rc replaces"
else
   ui_print "  - Adding rc files to boot.img:"
   for file in $(busybox ls)
         do
            if [[ $file == *"ramdisk.cpio"* ]]; then
                 # Nothing
                 log "Skipped $file"
            elif [[ $file == *"patch.sh"* ]]; then
                 # Nothing
                 log "Skipped $file"
            else
                 ui_print "   * Adding ${file}"
                 busybox echo "\"add 755 ${file} ${file}\" \\" >> $script
            fi
done
fi

# Add dm-verity/forceencrypt patch line, then run script
ui_print "   * Removing dm-verity,forceencryptition if found.."
busybox echo "\"patch $KEEPVERITY $KEEPFORCEENCRYPT\"" >> $script
chmod 755 $script
. ./$script

# Ship out the new cpio, and return
rm -f ramdisk.cpio.orig
cd $TMPDIR
mv $BOOTDIR/ramdisk.cpio ramdisk.cpio
}

port_boot() {
cd $TMPDIR
fix_some

# Find boot.img partition from device blocks/fstab, this is the advanced way
ui_print "  - Finding boot image partition"
find_boot_image

# Support kitkat kernel & older. (boot part dont have img header)
ui_print "  - Converting boot image"
convert_boot_image

# Unpack boot from raw boot image (kitkat and older are suppprted)
ui_print "  - Unpacking boot image"
boot --unpack $BOOTIMAGEFILE && ui_print "   * Boot unpacked to $TMPDIR" || ex "  ! Unable to unpack boot image!"

# Check if zImage found. then replace kernel
if [ -f $BOOTDIR/zImage ]; then
    ui_print "  - Replacing Kernel.."
    rm -f kernel
    mv $BOOTDIR/zImage kernel
else
    ex "  ! No zImage present in boot folder, aborting.."
fi

# Call ramdisk patch function
patch_ramdisk

# Repack the boot.img as new-boot.img
fix_recovery
ui_print "  - Repacking boot image"
cd $TMPDIR
busybox mv $TMPDIR/bin/boot $TMPDIR/boottool
busybox chmod 755 boottool
./boottool --repack $BOOTIMAGEFILE && ui_print "   * Boot repacked to new-boot.img" || ex "  ! Unable to repack boot image!"
unfix_recovery

# Flash the new boot.img
ui_print "  - Flashing the new boot image"
flash_image new-boot.img $BOOTIMAGE

cd $ROOTDIR
}

################
#              #
# SCRIPT START #
#              #
################

setup_flashable

ui_print " - Main Script Started."

mount_system

get_flags

ui_print " - Adding Build.prop changes..."

prop_append "$buildprop" "$systemprop"

ui_print " - Porting Boot.img started:"

port_boot

ui_print " - Patching power-profile to frameworks-res:"

change_power

ui_print " - Fixing /system permissions"

fix_permissions

clean_all

ui_print " - Main Script Ended.."
