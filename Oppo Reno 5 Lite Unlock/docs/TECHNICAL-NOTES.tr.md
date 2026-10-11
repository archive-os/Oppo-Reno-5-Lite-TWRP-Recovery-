# Teknik notlar ve geri dönüş

[English](TECHNICAL-NOTES.md)

[Güncel adım adım rehbere dön](../README.tr.md)

Bu dosya deneyimin ayrıntılarını ve kurtarma sınırlarını içerir. Kurulum ve kilit açma için ana rehberi izleyin. Aşağıdaki MTKClient komutlarını `mtkclient/` klasöründe çalıştırın; kurulu sanal ortamı kullanın.

## Sonuç ve kapsam

Tek CPH2205/F.72 cihazında denendi. BOOT1 yazımı geri okunup byte düzeyinde karşılaştırıldı. Kullanıcı normal açılış ve fastboot unlock sonrasında Android'den `ro.boot.flash.locked=0`, `ro.boot.vbmeta.device_state=unlocked`, `ro.boot.verifiedbootstate=orange` çıktılarını paylaştı. LineageOS 20 DSU açılışı ADB ile doğrulandı; SIM/RIL sorunu görüldü. Bu sonuçlar başka cihaz veya sürüm için garanti değildir.
Bu rehber tüm Reno5 modellerine veya başka firmware sürümlerine uyumluluk garantisi vermez. Yöntem bize ait bir exploit değildir: patch aracı [Shocked-Cat/oppo-mtk-fastboot-unlock](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock), flash/okuma aracı [bkerler/mtkclient](https://github.com/bkerler/mtkclient) projesidir. İncelenen patch commit: `ecf8e2c6f967706e6ab55c4774141abb5d78d12f`; kullanılan MTKClient: 2.1.4, commit `cd25cf9c1ff6d36e82697ac2c798e69e9cfb78c3`.


## Sorunlar ve geri dönüş sınırı

- MTKClient'te `seccfg unlock` yazma başarısı bu cihazda yeniden açılıştan sonra Android'in `locked/green` bildirmesini değiştirmedi. Bu yüzden tek başına yeterli sayılmadı.
- Kullanılan MTKClient sürümünün non-XML UFS `lu1/lu2` yolunda yazılım hatası vardı. `ro ... --parttype boot1/boot2` okuması çalıştı; kod değiştirilmedi.
- Kilit açılmadan patchli vbmeta yazıldığında kullanıcı boot/recovery doğrulama hatası bildirdi ve özgün vbmeta'yı geri yükledi. Bu rehber vbmeta patchlemeyi veya GSI flashlamayı içermez.
- Cihaz hâlâ DA/BROM'da erişilebilirken, BOOT1'i özgün hâline döndürmek için **doğru cihazın özgün tam BOOT1 yedeğiyle** aşağıdaki yazma değerlendirilebilir. Geri okuma yine zorunludur. Cihaz erişilemiyorsa bu komut kurtarma sağlamaz; servis/test point gerekebilir.

```bash
./.venv/bin/python mtk.py wf backup/ufs-boot1-original.bin --parttype boot1
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-restored.bin --parttype boot1
cmp backup/ufs-boot1-original.bin backup/ufs-boot1-restored.bin
```

Preloader geri yüklemek Android/veri/seccfg değişikliklerinin tümünü geri almaz. Modifiye sistem varken `fastboot flashing lock` çalıştırmayın. Rastgele downgrade, `Format All` veya başka cihaz firmware'i kullanmayın.


## Kaynaklar

- [Shocked-Cat: patch aracı ve upstream yöntemi](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock)
- [Upstream CPH2205 destek listesi](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock/blob/main/support_list.md)
- [MTKClient kullanım yönergesi](https://github.com/bkerler/mtkclient/blob/main/README-USAGE.md)
- [Android bootloader kilit durumu](https://source.android.com/docs/core/architecture/bootloader/locking_unlocking)


## Lisans

Bu depodaki özgün rehber metni CC BY 4.0 altında paylaşılır; bkz. [LICENSE](../LICENSE). Bağlantı verilen araçlar kendi lisanslarına tabidir. `tools/path_preloader.py` değişiklik yapılmadan upstream kaynaktan alınmıştır; AGPL-3.0 lisansı ve commit bilgisi `tools/` altında korunur. Cihaza ait imajlar dağıtılmaz.


## Patch sırasında gözlenen değişiklik

Bu deneyimde kaynakta `UFS_BOOT`, `BRLYT` ve tek bir `AND_ROMINFO_v` bloğu bulundu. Araç kod başlangıcını `0x1000` konumundan `0x2000` konumuna taşıdı, BRLYT başlığını güncelledi ve `0x1000` konumuna kopyalanan ROMINFO bloğunun `0x104c` kilit bayrağını `0x22` değerinden `0x00` değerine değiştirdi. Taşınan preloader kodunun byte eşliği ve 4 MiB çıktı boyutu kontrol edildi. Bu kontroller telefonun patchi kabul edeceğini garanti etmez.
