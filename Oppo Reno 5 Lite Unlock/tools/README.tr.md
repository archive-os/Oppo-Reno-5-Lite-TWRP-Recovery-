# Araçlar

[English](README.md)

[Adım adım rehbere dön](../README.tr.md)

Bu klasördeki araçları ana rehberin sırasıyla kullan. Telefonun yedeğini veya değiştirilmiş imajını bu klasöre koyma.

| Dosya | Açıklama |
| --- | --- |
| `mtkclient-2.1.4-source.zip` | Telefon bölümlerini okuyan/yazan MTKClient'in kaynak paketi; GUI ve komut satırı aracı içerir. |
| `path_preloader.py` | Kendi tam BOOT1 yedeğinin değiştirilmiş kopyasını bilgisayarda oluşturur. Telefona yazmaz. |
| `open-mtk-gui.sh` | Kurulmuş MTKClient'in görsel arayüzünü açar. |
| `MTKCLIENT-UPSTREAM.md` | MTKClient kaynağı, sürümü ve lisansı. |
| `UPSTREAM.md` | Patch aracının kaynağı ve commit bilgisi. |
| `LICENSE-AGPL-3.0` | Patch aracının lisansı. |

Kurulumdan sonra rehber klasöründe GUI'yi açmak için:

```bash
sh tools/open-mtk-gui.sh
```

MTKClient başka yerde kuruluysa tam yolu ver:

```bash
sh tools/open-mtk-gui.sh "/tam/yol/mtkclient"
```

Ana rehberdeki komut satırı işlemlerine başlamadan GUI'yi kapat.
