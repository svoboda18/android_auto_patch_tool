
Auto Patch Tool
===================

# Welcome:
- Welcome To Auto ROM Patcher Tool (ZIP) Git Repo
Read This Carefuly, It Will Help You Bypass Mistaks.
Also, It Will Let You Know How To Use This Zip Correctly, In Results Your Patch Will Work Sucessfully.

# Info's:
- **Current Version:** V1.5 (BETA)
- **Current Stable Version:** V1.0 (First Stable)
- **Current Features:**
   * Automaticly Edit Boot.img With:
      - Replacing Kernel (OPTIMAL)
      - Change/Replace .rc Files (OPTIMAL)
      - Append/Change default.prop Lines. (OPTIMAL)
      - Patch Remove DM-Verity / Force Encrypt If Found.
   * Patch framework-res.apk With power_profile.xml. (Stock Of The Device) (OPTIMAL)
      - With Undo Flashable Patch (in cases it get rejected by fw/device stays in boot-animation loop)
        Thats Will Be Located at: /sdcard/fpatcherundo/UndoFwPatch.zip
   * Advancedly Replace Files On /system. (OPTIMAL)
   * Advancedly Replace Files On /vendor. (OPTIMAL)
   * Append/Chnage build.prop Lines. (OPTIMAL)

# Usage Guide:

 **Flash Method:**
This zip, can patch a rom, you must follow this to get it work:
- Reboot to recovery
- Locate the auto patch zip, and flash it
  * The patch zip,must be made for your current rom (uses your kernel,libs,etc)
- Reboot and enjoy!

 **Files/Folders Usage:**
Let's talk about the changes/zip folders/files you must do/have to:
- defualt.prop, contians lines to be added/changed in boot's image default.prop.
  * Some lines can make bootloop like "ro.kernel.qemu=1" , so be careful!.
  * Dont add use-less lines, it will make things bad.
- build.prop, contians lines to be added/changed in system's build.prop.
  * Some lines can make bootloop like "ro.kernel.qemu=1" , so be careful!.
  * Dont add use-less lines, it will make things bad.
- power_profile.xml, taked from stock device rom. (located in: /system/framework/framework-res.apk/res/xml/power_profile.xml), it has device's battery mAh, cpu speeds & etc.
  * It must be in un-decoded (encoded) format, unless the rom will bootloop.
- In boot folder, there files to be added/replaced to boot.img, kernel must be placed there with zImage as name.
  * If you add defualt.prop in boot folder, make sure it correct.
- In system folder, there files to be replaced/changed in /system partition.
- In vendor folder, there files to be replaced/changed in /vendor partition.
  * Dont touch scripts folder /or/ META-INF, do it at your own risk.

So now, add your required changes & go flash !

# Acknowledgement:
| topjohnwu | magiskboot tool and some other functions|
|:---------:|-------------------------------------------|
| kl3       | for great prop_append() |

## See you in newer versions!
