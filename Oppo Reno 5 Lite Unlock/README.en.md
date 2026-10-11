# OPPO Reno 5 Lite Unlock

[Full step-by-step guide with commands](README.md) · [Türkçe](README.tr.md)

A documented single-device experience with **OPPO Reno 5 Lite CPH2205, Android 13, CPH2205_11_F.72**, using a modified factory UFS BOOT1 image to enable fastboot, followed by `fastboot flashing unlock`.

## Evidence and limits

The BOOT1 write was read back and compared byte for byte with the patched image. The owner reported successful Android boot, fastboot enumeration, an on-screen `fastboot unlock verify ok` message, successful bootloader unlock and subsequent Android boot. The owner subsequently supplied Android properties `0 / unlocked / orange`. LineageOS 20 DSU boot was verified through ADB, with a SIM/RIL issue. These results do not establish compatibility with other devices or firmware.

**Writing a modified preloader can brick the device. Unlocking wipes personal data. Backups do not guarantee recovery if BROM becomes inaccessible.** No success rate or compatibility with other firmware/models is claimed.

## Method

1. Enable OEM unlocking and USB debugging; back up personal data and firmware partitions.
2. Read both separate UFS boot areas with MTKClient. On this device each was 4 MiB. A normal GPT partition backup did not include them.
3. Use the device's own full `UFS_BOOT` BOOT1 backup with [Shocked-Cat's patch tool](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock). A small extracted RAW preloader is not supported by that tool.
4. Check the generated image before flashing. The reviewed tool moves the preloader payload and updates its layout and copied fastboot flag; it does not merely flip a byte in place.
5. Re-read the current BOOT1 and compare it with the original backup. Write only BOOT1 for this non-A/B layout. Read back and compare with the patched file before rebooting. BOOT2 was left untouched.
6. Boot Android, use `adb reboot bootloader`, confirm `fastboot devices`, then run `fastboot flashing unlock` and accept the phone's confirmation screen.
7. Reboot and verify lock-state properties before attempting any custom system installation.

For the exact commands, device-specific length assumptions, original-image restoration path and troubleshooting, use the [full guide](README.md). Do not apply A/B assumptions, other-device images or arbitrary downgrade instructions.

## GSI and image downloads

The maintainer shares OPPO Reno 5 Lite GSIs and images on Telegram: [Join the Telegram group](https://t.me/+fctoFSsmWJxjYmVk).

## Credits

This repository documents an experience; it does not implement a new exploit.

- Patch tool: [Shocked-Cat/oppo-mtk-fastboot-unlock](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock), reviewed commit `ecf8e2c6f967706e6ab55c4774141abb5d78d12f`.
- Read/write utility: [bkerler/mtkclient](https://github.com/bkerler/mtkclient), version 2.1.4, commit `cd25cf9c1ff6d36e82697ac2c798e69e9cfb78c3`.
- [Android bootloader locking documentation](https://source.android.com/docs/core/architecture/bootloader/locking_unlocking).

**I accept no responsibility if your device is bricked, data is lost, or any other damage occurs. Proceed at your own risk.**

No device firmware, preloader, BOOT1/BOOT2 or personal backups are distributed in this repository. Read and patch your own device's backup. Do not upload your backups or patched images.

The unmodified upstream patch script and AGPL-3.0 license are included in `tools/`. The main guide provides one numbered Linux setup and unlock workflow. Technical evidence and restoration limits are in [technical notes](docs/TECHNICAL-NOTES.md); bundled files are explained in [tools/README.md](tools/README.md). From this repository folder, patch your own full UFS backup with:

```bash
python3 tools/path_preloader.py /path/to/your-own-ufs-boot1-original.bin boot1-patched.bin
```

Output is `preloader_path/boot1-patched.bin`; this command does not flash a phone. Verify bundled tool files with `sha256sum -c SHA256SUMS`. Never feed the small extracted RAW preloader to this tool.

Original documentation is licensed under [CC BY 4.0](LICENSE); third-party tools retain their own licenses. No firmware images are distributed.

## Back up first and bundled tools

**Back up the full ROM/partitions, both separate UFS boot areas, and personal data before starting. Keep calibration backups private. Backups do not guarantee recovery.** The actual GUI/CLI source package is [bundled here](tools/mtkclient-2.1.4-source.zip), with [upstream attribution](tools/MTKCLIENT-UPSTREAM.md). Setup, GUI launch, CLI backup and patch commands are in the [full guide](README.md).
