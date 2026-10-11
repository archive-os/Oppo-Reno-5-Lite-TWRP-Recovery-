# Technical notes and restoration

[Türkçe](TECHNICAL-NOTES.tr.md) · [Back to the step-by-step guide](../README.md)

This file records the tested procedure and its recovery limits. Follow the main guide for installation and unlocking. Run the MTKClient commands below from `mtkclient/` using the installed virtual environment.

## Evidence and scope

The procedure was tested on one CPH2205/F.72 device. The BOOT1 write was read back and compared byte for byte. After normal boot and fastboot unlock, the owner supplied Android properties `ro.boot.flash.locked=0`, `ro.boot.vbmeta.device_state=unlocked`, and `ro.boot.verifiedbootstate=orange`. LineageOS 20 DSU boot was verified through ADB; a SIM/RIL issue was observed. These results do not guarantee success on another device or firmware version.

Compatibility with all Reno5 models or other firmware versions is not claimed. This repository does not implement a new exploit: the patch tool is from [Shocked-Cat/oppo-mtk-fastboot-unlock](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock), and the read/write tool is [bkerler/mtkclient](https://github.com/bkerler/mtkclient). Reviewed patch commit: `ecf8e2c6f967706e6ab55c4774141abb5d78d12f`. MTKClient version: 2.1.4, commit `cd25cf9c1ff6d36e82697ac2c798e69e9cfb78c3`.

## Issues and restoration limits

- MTKClient reported a successful `seccfg unlock` write, but Android still reported `locked/green` after reboot on this device. That result was not considered sufficient.
- The MTKClient version used had a software issue in its non-XML UFS `lu1/lu2` path. Reading with `ro ... --parttype boot1/boot2` worked; the code was not modified.
- When patched vbmeta was written before unlocking, the owner reported boot/recovery verification errors and restored the original vbmeta. This guide does not cover vbmeta patching or GSI flashing.
- If the device remains accessible through DA/BROM, restoring BOOT1 may be considered using **that device's own original full BOOT1 backup**. Read-back verification remains required. These commands cannot recover an inaccessible device; service or test-point access may be necessary.

The 4 MiB length below applies only to the tested device, as in the main guide.

```bash
./.venv/bin/python mtk.py wf backup/ufs-boot1-original.bin --parttype boot1
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-restored.bin --parttype boot1
cmp backup/ufs-boot1-original.bin backup/ufs-boot1-restored.bin
```

Writing and reading must both succeed. `cmp` must finish silently with exit code 0. Do not reboot if verification fails.

Restoring the preloader does not undo every Android, data, or seccfg change. Do not run `fastboot flashing lock` with a modified system installed. Do not use arbitrary downgrades, `Format All`, or firmware from another device.

## Sources

- [Shocked-Cat: patch tool and upstream method](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock)
- [Upstream CPH2205 support list](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock/blob/main/support_list.md)
- [MTKClient usage instructions](https://github.com/bkerler/mtkclient/blob/main/README-USAGE.md)
- [Android bootloader lock state](https://source.android.com/docs/core/architecture/bootloader/locking_unlocking)

## License

Original documentation in this repository is shared under CC BY 4.0; see [LICENSE](../LICENSE). Linked tools retain their own licenses. `tools/path_preloader.py` was copied unmodified from upstream; its AGPL-3.0 license and commit information are preserved in `tools/`. Device images are not distributed.

## Observed patch changes

The original image contained `UFS_BOOT`, `BRLYT`, and one `AND_ROMINFO_v` block. The tool moved the code start from `0x1000` to `0x2000`, updated the BRLYT header, and changed the lock flag at `0x104c` in the ROMINFO block copied to `0x1000` from `0x22` to `0x00`. The relocated preloader code was checked for byte equality, and the output was verified to remain 4 MiB. These checks do not guarantee that the phone will accept the patch.
