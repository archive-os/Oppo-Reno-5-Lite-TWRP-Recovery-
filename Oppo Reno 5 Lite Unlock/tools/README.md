# Tools

[Türkçe](README.tr.md) · [Back to the step-by-step guide](../README.md)

Use these tools in the order shown in the main guide. Keep phone backups and patched images outside this directory.

| File | Description |
| --- | --- |
| `mtkclient-2.1.4-source.zip` | MTKClient source package for reading/writing phone partitions; includes GUI and command-line tools. |
| `path_preloader.py` | Creates a patched copy of your own full BOOT1 backup on your computer. Does not write to the phone. |
| `open-mtk-gui.sh` | Opens the installed MTKClient graphical interface. |
| `MTKCLIENT-UPSTREAM.md` | MTKClient source, version, and license details. |
| `UPSTREAM.md` | Patch tool source and commit information. |
| `LICENSE-AGPL-3.0` | Patch tool license. |

After installation, open the GUI from the guide folder:

```bash
sh tools/open-mtk-gui.sh
```

If MTKClient is installed elsewhere, provide its full path:

```bash
sh tools/open-mtk-gui.sh "/absolute/path/to/mtkclient"
```

Close the GUI before starting the command-line steps in the main guide.
