#!/sbin/sh
ver=0.1
ROOTDIR=/
TMPDIR=/tmp
systemprop=/system/build.prop
buildprop=$TMPDIR/build.prop
defaultprop=$TMPDIR/default.prop
bootprop=$TMPDIR/boot/default.prop

mount_all() {
for part in system
do
	if mount | grep -q "/$part"
	then
		mount -o rw,remount "/$part" "/$part" && log "$part mounted"
	else
		mount -o rw "/$part" && log "$part mounted"
	fi
done
}

clean_all() {
rm -rf TMPDIR
}

get_flags() {
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
    # Make sure this path is in the front
    echo $PATH | grep -q "^$TMPDIR/bin" || export PATH=$TMPDIR/bin:$PATH
    $TMPDIR/bin/busybox --install -s $TMPDIR/bin
}

setup_flashable() {
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

ui_print() {
  sleep 0.4
  echo -e "ui_print $1\n\nui_print" >> /proc/self/fd/$OUTFD
}

backup() {
     if [[ ! "$1" == *"default.prop"* ]]; then
     busybox rm -rf "${1}.bak"
     busybox echo $(cat "$1") >> "${1}.bak"
     fi
}

flash_image() {
    dd if="$1" of="$2"
}

log() {
	echo -n -e "$1\n"
}

ex() {
	ui_print "ERROR: $@, script aborted!"
	exit 1
}

prop_append() {
tweak="$1"
build="$2"

answer=$(sed "s/BACKUP=//p;d" "$tweak")
case "$answer" in
y|Y|yes|Yes|YES)
	## use same directory where tweak.prop was found
	backup "$systemprop"
	;;

n|N|no|No|NO)
	;;

*)
	## check if empty or invalid
	[[ -z "$answer" || ! -d $(dirname "$answer") ]] && log "Given path is empty or parent directory does not exist" || backup "$answer"
	;;
esac
sleep 2
echo "" >> $build
set -e
sed -r '/(^#|^ *$|^BACKUP=)/d;/(.*=.*|^\!|^\@.*\|.*|^\$.*\|.*)/!d' "$tweak" | while read line
do
	## remove entry
	if echo "$line" | grep -q '^\!'
	then
		entry=$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')
		## remove from $build if present
		grep -q "$entry" "$build" && (sed "/$entry/d" -i "$build" && ui_print "   * All lines containing \"$entry\" removed")

	## append string
	elif echo "$line" | grep -q '^\@'
	then
		entry=$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')
		var=$(echo "$entry" | cut -d\| -f1)
		app=$(echo "$entry" | cut -d\| -f2)
		## append string to $var's value if present in $build
		grep -q "$var" "$build" && (sed "s/^$var=.*$/&$app/" -i "$build" && ui_print "   * \"$app\" Appended to value of \"$var\"")

	## change value only iif entry exists
	elif echo "$line" | grep -q '^\$'
	then
		entry=$(echo "${line#?}" | sed -e 's/[\/&]/\\&/g')
		var=$(echo "$entry" | cut -d\| -f1)
		new=$(echo "$entry" | cut -d\| -f2)
		## change $var's value iif $var present in $build
		grep -q "$var=" "$build" && (sed "s/^$var=.*$/$var=$new/" -i "$build" && ui_print "   * Value of \"$var\" changed to \"$new\"")

	## add or override entry
	else
		var=$(echo "$line" | cut -d= -f1)
		## if variable already present in $build
		if grep -q "$var" "$build"
		then
			## override value in $build if different
			grep -q $(grep "$var" "$tweak") "$build" || (sed "s/^$var=.*$/$line/" -i "$build" && ui_print "   * Value of \"$var\" overridden")
		## else append entry to $build
		else
			echo "$line" >> "$build" && ui_print "   * Entry \"$line\" added"
		fi
	fi
done

## trim empty and duplicate lines of $build
sed '/^ *$/d' -i "$build"
}

patch_ramdisk() {
script=patch.sh
mv ramdisk.cpio boot/ramdisk.cpio
cd $TMPDIR/boot

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

echo "boot --cpio ramdisk.cpio \\" >> $script

if [[ `busybox ls | grep -Eo 'default.prop'` == *"default.prop"* ]]; then
   ui_print "   ! boot folder empty, skipping .rc replaces"
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
           echo "\"add 755 ${file} ${file}\" \\" >> $script
      fi
done

fi
ui_print "   * Removing dm-virty,force encryptition if found.."
echo "\"patch $KEEPVERITY $KEEPFORCEENCRYPT\"" >> $script
chmod 755 $script
./$script
cd $TMPDIR
mv boot/ramdisk.cpio ramdisk.cpio
}

port_boot() {
cd $TMPDIR

BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
boot --unpack $BOOTIMAGE || ex " ! Cant Unpack Boot.img"

if [ ! -f boot/zImage ]; then
ex "Kernel File Was Not Found, Aborting"
fi

rm -f kernel
mv boot/zImage kernel

patch_ramdisk

boot --repack $BOOTIMAGE || ex " ! Cant Repack Boot.img"

flash_image new-boot.img $BOOTIMAGE

mv new-boot.img /sdcard/ported_boot_image.img

cd $ROOTDIR
}

setup_flashable

ui_print " - Main Script Started."

mount_all

get_flags

ui_print " - Adding Build.prop changes..."

prop_append "$buildprop" "$systemprop"

ui_print " - Porting Boot.img.."

port_boot

#clean_all

ui_print " - Main Script Ended.."
