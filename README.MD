---------------------------------------------
* Auto Porter ZIP by svoboda18
---------------------------------------------

# Welcome:
- Welcome To Auto ZIP Git Repo
Read This Carefuly, It Will Help You Bypass Mistaks.
It Will Let You Know How To Use This Zip Correctly, In Results You Port The ROM Sucessfully.

# Info
- Current Version: V0.5 (BETA)
- Current Stable Version: N/A
- Current Features: 
   * Automaticly Port Boot.img With:
      - Change/Replace .rc Files
      - Append/Change default.prop Lines.
      - Patch Remove DM-Verity / Force Encrypt.
   * Patch framework-res.apk With power_profile.xml. (Stock Of The Device)
      - With Undo Flashable Patch (in cases it get rejected by fw/device stays in boot-animation loop)
        Thats Will Be Located at: /sdcard/fpatcherundo/UndoFwPatch.zip
   * Replace Libs On System.
   * Append/Chnage build.prop Lines.
- Next Features: (TODO)
   * Multip SDK Support.
   * More !

# Usage Info:
This zip, can port a rom, it must be flashed after port rom installed. (unported)

Let's talk about the changes/zip folders/files you must do/have to:
- defualt.prop, contians lines to be added/changed in port boot's image. (Always keep the file as it is, just add to end of it.)
  * dont remove BACKUP= line, it nessecery.
- build.prop, contians lines to be added/changed in port system's build.prop. (Always keep the file as it is, just add to end of it.)
  * dont remove BACKUP= line, it nessecery.
- power_profile.xml, taked from stock device rom. (located in: /system/framework/framework-res.apk/res/xml/power_profile.xml), it has device's battery mAh, cpu speeds & etc.
  * it must be in un-decoded (encoded) formar, unless the rom will bootloop.
- in boot folder, there files to be added/replaced to boot.img, kernel must be placed there with zImage as name.
  * You must add zImage To it or autoport will fail.
  * if you add defualt.prop in boot folder, make sure it correct.
- in system folder, there files to be replaces/chnaged in /system partition.
  * dont touch scripts folder/META-INF, do it at your own risk.

so now, add your required changes & go flash !

# Thanks
| Thanks To | For |
| :-------| :-------|
| topjohnwu | magiskboot tool and some functions |
| kl3 | prop_append function |

# See you in newer versions!
