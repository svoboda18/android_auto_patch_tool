
Auto Porter ZIP
===================

# Welcome:
- Welcome To Auto ROM Porter ZIP Git Repo
Read This Carefuly, It Will Help You Bypass Mistaks.
Also, It Will Let You Know How To Use This Zip Correctly, In Results You Port The ROM Sucessfully.

# Info
- **Current Version:** V1.0 (STABLE)
- **Current Stable Version:** V1.0 (First Stable)
- **Current Features:**
   * Automaticly Port Boot.img With:
      - Change/Replace .rc Files (OPTIMAL)
      - Append/Change default.prop Lines. (OPTIMAL)
      - Patch Remove DM-Verity / Force Encrypt If Found.
   * Patch framework-res.apk With power_profile.xml. (Stock Of The Device) (OPTIMAL)
      - With Undo Flashable Patch (in cases it get rejected by fw/device stays in boot-animation loop)
        Thats Will Be Located at: /sdcard/fpatcherundo/UndoFwPatch.zip
   * Advancedly Replace Files On System.
   * Append/Chnage build.prop Lines. (OPTIMAL)

# Usage Info:

 **Flash Method:**
This zip, can port a rom, you must follow this to get it work:
- Reboot to recovery
- Flash other device port rom (unported)
- Restart recovery (In TWRP Home Page, Go To Reboot Tab > Hit Recovery)
- Locate the auto port zip, and flash it
  * Port zip,must be made for your device (uses your kernel,libs,etc)
- Reboot and enjoy!

 **Files/Folders Usage:**
Let's talk about the changes/zip folders/files you must do/have to:
- defualt.prop, contians lines to be added/changed in port boot's image. (Always keep the file as it is, just add to end of it.)
  * Dont remove BACKUP= line, it nessecery.
  * Some lines can make bootloop like "ro.kernel.qemu=1" , so be careful!.
  * Dont add use-less lines, it will make things bad.
- build.prop, contians lines to be added/changed in port system's build.prop. (Always keep the file as it is, just add to end of it.)
  * Dont remove BACKUP= line, it nessecery.
  * Some lines can make bootloop like "ro.kernel.qemu=1" , so be careful!.
  * Dont add use-less lines, it will make things bad.
- power_profile.xml, taked from stock device rom. (located in: /system/framework/framework-res.apk/res/xml/power_profile.xml), it has device's battery mAh, cpu speeds & etc.
  * It must be in un-decoded (encoded) format, unless the rom will bootloop.
- In boot folder, there files to be added/replaced to boot.img, kernel must be placed there with zImage as name.
  * You must add zImage To it or autoport will fail.
  * If you add defualt.prop in boot folder, make sure it correct.
- In system folder, there files to be replaces/changed in /system partition.
  * Dont touch scripts folder/META-INF, do it at your own risk.

So now, add your required changes & go flash !

# Thanks
| Thanks To | For |
| -------   | -------|
| topjohnwu | magiskboot tool and some functions |
| kl3 | prop_append function |

## See you in newer versions!
