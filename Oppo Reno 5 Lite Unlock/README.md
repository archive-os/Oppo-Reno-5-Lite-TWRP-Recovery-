# OPPO Reno 5 Lite — easy unlock guide

This guide describes a procedure tested on **OPPO Reno 5 Lite CPH2205 / Android 13 / CPH2205_11_F.72**. It was tested on one device only; compatibility with other models or firmware versions is not guaranteed.

The goal is to modify a copy of your phone's own BOOT1 backup, write it back to the phone, and then unlock the bootloader. The bootloader lock controls which system the phone can boot.

**Unlocking erases personal data. Writing the wrong BOOT1 image can prevent the phone from starting and may require service. Backups do not guarantee recovery.**

[Türkçe](README.tr.md) · [Technical notes and restoration](docs/TECHNICAL-NOTES.md) · [Tool files](tools/README.md)

## 1. Check before starting

- [ ] Your model and firmware match the versions above. Check **Settings → About phone**.
- [ ] You have an Ubuntu/Linux computer and a reliable USB cable.
- [ ] Your photos and personal files are backed up on another drive.
- [ ] **OEM unlocking** and **USB debugging** are enabled in Developer options.

If OEM unlocking is missing or cannot be enabled, stop here. Do not use images from another phone.

## 2. Install the tools on your computer

Open the downloaded guide folder. Right-click an empty area and choose **Open in Terminal**. Run these commands in order:

```bash
sudo apt install unzip build-essential python3-venv python3-dev libssl-dev libusb-1.0-0 libxcb-cursor0 adb fastboot
sha256sum -c SHA256SUMS
```

**Check:** Every listed file must show `OK` (or the equivalent in your system language). Stop if any check fails.

```bash
unzip tools/mtkclient-2.1.4-source.zip -d mtkclient
cd mtkclient
python3 -m venv .venv
./.venv/bin/python -m pip install . keystone-engine capstone unicorn
sudo cp Setup/Linux/52-mtk.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb
```

**Run all remaining commands from the `mtkclient/` directory.** If you open another terminal, run `cd mtkclient` from the guide folder. If an installed `mtkclient/` directory already exists, do not extract the ZIP over it.

To open the optional graphical interface:

```bash
./.venv/bin/python mtk_gui.py
```

Close this window before running the command-line steps below. Both tools must not access the phone at the same time. For installation or USB permission issues, see the [official MTKClient installation instructions](https://github.com/bkerler/mtkclient/blob/main/README-INSTALL.md).

## 3. Back up your phone

**You need three kinds of backup:** personal files, ROM partitions, and BOOT1/BOOT2. One does not replace another.

Turn off the phone and disconnect USB. Start the read command below. When it waits for a connection, **hold the volume buttons and connect USB**. Wait for MTKClient to establish a BROM connection. Repeat this connection procedure whenever another read command waits for the phone.

Read the ROM partitions first:

```bash
mkdir -p backup/partitions
./.venv/bin/python mtk.py rl backup/partitions
```

**Check:** Reading must finish without errors, and backup files must appear in `backup/partitions/`. Stop if reading fails. Do not use `Format All`.

Now read the separate boot areas. **The size below applies only to the tested device.** If MTKClient reports BOOT1 or BOOT2 sizes other than 4 MiB (`0x400000`), stop; do not use these commands unchanged.

```bash
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-original.bin --parttype boot1
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot2-original.bin --parttype boot2
wc -c backup/ufs-boot1-original.bin backup/ufs-boot2-original.bin
sha256sum backup/ufs-boot1-original.bin backup/ufs-boot2-original.bin
```

**Check:** Both reads must succeed. In the `wc` output, each file must be **4194304** bytes; the `total` line is their combined size. The two files do not need to have matching hashes.

Copy the entire `backup/` folder to another drive as well. Keep these backups private; partitions such as NVRAM/NVDATA contain device-specific information.

## 4. Create a patched BOOT1 copy

This step creates a file on your computer. It does not write to the phone.

```bash
python3 ../tools/path_preloader.py backup/ufs-boot1-original.bin ufs-boot1-patched.bin
```

Press Enter if the tool finishes with `Press Enter to close`. **If it warns about size, an unknown file type, or a missing flag, stop instead of approving continuation.** A small extracted RAW preloader is not suitable for this tool.

The generated file is `mtkclient/preloader_path/ufs-boot1-patched.bin`.

```bash
wc -c preloader_path/ufs-boot1-patched.bin
```

**Check:** The output must also be **4194304** bytes. Correct size alone does not prove the image is safe. The tool may overwrite an existing output with the same name; keep your original backup outside `preloader_path/`.

## 5. Write BOOT1 and verify it

**This step changes the phone.** Make sure your backups are also on another drive. The tested device did not use an A/B partition layout, and only BOOT1 was written. Stop here if your device uses an A/B layout.

First, read the phone's current BOOT1 again:

```bash
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-before-write.bin --parttype boot1
cmp backup/ufs-boot1-original.bin backup/ufs-boot1-before-write.bin && echo "OK: original backup matches"
```

**Check:** The `OK` message must appear. Stop if there is a difference or an error.

Write the patched file:

```bash
./.venv/bin/python mtk.py wf preloader_path/ufs-boot1-patched.bin --parttype boot1
```

If writing succeeds, read it back and compare:

```bash
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-after-write.bin --parttype boot1
cmp preloader_path/ufs-boot1-patched.bin backup/ufs-boot1-after-write.bin && echo "OK: written image matches"
```

**Check:** Writing and reading must succeed, and the `OK` message must appear. **Do not reboot the phone if there is an error or a difference.** [Read the restoration notes](docs/TECHNICAL-NOTES.md#issues-and-restoration-limits). Do not write BOOT2.

## 6. Start the phone and unlock it

Once the read-back matches:

```bash
./.venv/bin/python mtk.py reset
```

Disconnect USB and wait for Android to boot. Reconnect USB and approve the phone's USB debugging authorization prompt.

```bash
adb reboot bootloader
fastboot devices
```

**Check:** `fastboot devices` must list a device. Stop if the list is empty. An on-screen `fastboot unlock verify ok` message alone does not prove the bootloader is unlocked.

**The next command erases personal data:**

```bash
fastboot flashing unlock
```

Read the confirmation screen on the phone and confirm using the volume button indicated there. If unlocking succeeds:

```bash
fastboot reboot
```

## 7. Verify the unlocked state

Complete the phone's initial setup. Enable USB debugging again and authorize your computer's connection.

```bash
adb shell getprop ro.boot.flash.locked
adb shell getprop ro.boot.vbmeta.device_state
adb shell getprop ro.boot.verifiedbootstate
```

Expected results, in command order:

| Property at the end of the command | Expected output |
| --- | --- |
| `ro.boot.flash.locked` | `0` |
| `ro.boot.vbmeta.device_state` | `unlocked` |
| `ro.boot.verifiedbootstate` | `orange` |

All three matching results confirm the unlocked state. Treat empty or different results as unconfirmed. Do not write a GSI or modified vbmeta before confirming unlock. This guide does not cover ROM installation.

## Where are the files?

| File / directory | Purpose |
| --- | --- |
| `README.md` | This English step-by-step guide |
| `README.tr.md` | Turkish step-by-step guide |
| `README.en.md` | English overview |
| `docs/TECHNICAL-NOTES.md` | Evidence, sources, and restoration limits in English |
| `docs/TECHNICAL-NOTES.tr.md` | Technical notes in Turkish |
| `tools/` | Bundled tools, patch code, licenses, and bilingual tool documentation |
| `SHA256SUMS` | Integrity checks for bundled tool files |
| `mtkclient/backup/` | Your original backups, created after installation |
| `mtkclient/preloader_path/` | The patched file created from your backup |

This repository contains no phone firmware or personal backups. Each user must use their own backup. The method and tools come from [Shocked-Cat](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock) and [bkerler/mtkclient](https://github.com/bkerler/mtkclient); version and license details are preserved in the [technical notes](docs/TECHNICAL-NOTES.md).

No responsibility is accepted for a bricked device, data loss, or other damage. Proceed at your own risk. The documentation is shared under [CC BY 4.0](LICENSE); tools retain their own licenses.
