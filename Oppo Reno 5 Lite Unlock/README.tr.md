# OPPO Reno 5 Lite — kolay kilit açma rehberi

Bu rehber, **OPPO Reno 5 Lite CPH2205 / Android 13 / CPH2205_11_F.72** üzerinde denenmiş işlemi anlatır. Yalnız bir cihazda denendi; başka model veya sürümde çalışacağı garanti değildir.

Amaç: telefonun kendi BOOT1 yedeğini bilgisayarda değiştirmek, telefona yazmak ve ardından bootloader kilidini açmak. Bootloader, telefonun açılışta hangi sistemi çalıştırabileceğini denetleyen kilittir.

**Kilit açma kişisel verileri siler. BOOT1'e yanlış dosya yazmak telefonu açılmaz hâle getirebilir ve servis gerektirebilir. Yedek almak kurtarmayı garanti etmez.**

[English](README.md) · [Teknik notlar ve geri dönüş](docs/TECHNICAL-NOTES.tr.md) · [Araç dosyaları](tools/README.tr.md)

## 1. Başlamadan önce kontrol et

- [ ] Model ve sürüm yukarıdakiyle aynı. Telefonun **Ayarlar → Telefon hakkında** ekranından kontrol et.
- [ ] Ubuntu/Linux bilgisayar ve sağlam USB kablosu hazır.
- [ ] Fotoğraflar ve kişisel dosyalar başka bir diske yedeklendi.
- [ ] Geliştirici seçeneklerinde **OEM kilit açma** ve **USB hata ayıklama** açık.

OEM kilit açma seçeneği yoksa veya açılamıyorsa burada dur. Başka telefondan alınmış dosya kullanma.

## 2. Bilgisayara araçları kur

İndirdiğin rehber klasörünü aç. Boş bir alana sağ tıkla ve **Terminalde aç** seçeneğini kullan. Aşağıdaki komutları sırayla çalıştır:

```bash
sudo apt install unzip build-essential python3-venv python3-dev libssl-dev libusb-1.0-0 libxcb-cursor0 adb fastboot
sha256sum -c SHA256SUMS
```

**Kontrol:** Listelenen bütün dosyalarda `OK` veya `TAMAM` görmelisin. Hata varsa devam etme.

```bash
unzip tools/mtkclient-2.1.4-source.zip -d mtkclient
cd mtkclient
python3 -m venv .venv
./.venv/bin/python -m pip install . keystone-engine capstone unicorn
sudo cp Setup/Linux/52-mtk.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb
```

**Buradan sonraki bütün komutlar `mtkclient/` klasöründe çalıştırılır.** Yeni terminal açarsan rehber klasöründen `cd mtkclient` yaz. Kurulu bir `mtkclient/` klasörü varsa ZIP'i onun üzerine açma.

İsteğe bağlı görsel arayüzü açmak için:

```bash
./.venv/bin/python mtk_gui.py
```

Aşağıdaki komut satırı işlemlerinden önce bu pencereyi kapat. İkisi aynı anda telefonu kullanmasın. Kurulum/USB izin sorunu için [resmî MTKClient kurulum yönergesine](https://github.com/bkerler/mtkclient/blob/main/README-INSTALL.md) bak.

## 3. Telefonun yedeklerini al

**Üç ayrı yedek gerekir:** kişisel dosyalar, ROM bölümleri ve BOOT1/BOOT2. Birisi diğerinin yerine geçmez.

Telefonu kapat ve USB kablosunu çıkar. Aşağıdaki okuma komutunu başlat; bağlantı beklediğinde **ses tuşlarını basılı tutarak USB'yi bağla**. MTKClient'in BROM bağlantısını kurmasını bekle. Her okuma komutunda bağlantı yeniden beklenirse aynı işlemi tekrarla.

Önce ROM bölümlerini oku:

```bash
mkdir -p backup/partitions
./.venv/bin/python mtk.py rl backup/partitions
```

**Kontrol:** Okuma hatasız bitmeli ve `backup/partitions/` içinde yedek dosyaları oluşmalı. Hata varsa devam etme. `Format All` kullanma.

Şimdi ayrı boot alanlarını oku. **Aşağıdaki boyut sadece bu cihaz içindir.** MTKClient çıktısında BOOT1 ve BOOT2 boyutları 4 MiB (`0x400000`) değilse dur; bu komutları aynen uygulama.

```bash
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-original.bin --parttype boot1
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot2-original.bin --parttype boot2
wc -c backup/ufs-boot1-original.bin backup/ufs-boot2-original.bin
sha256sum backup/ufs-boot1-original.bin backup/ufs-boot2-original.bin
```

**Kontrol:** İki okuma da başarılı olmalı. `wc` çıktısında her dosya **4194304** bayt olmalı; `total` satırı iki dosyanın toplamıdır. İki dosyanın hash değerlerinin aynı olması şart değildir.

`backup/` klasörünün tamamını başka bir diske de kopyala. Bu yedekleri internette paylaşma; NVRAM/NVDATA gibi bölümler cihaza özel bilgiler içerir.

## 4. BOOT1'in değiştirilmiş kopyasını hazırla

Bu adım sadece bilgisayarda dosya oluşturur. Telefona yazmaz.

```bash
python3 ../tools/path_preloader.py backup/ufs-boot1-original.bin ufs-boot1-patched.bin
```

İşlem sonunda `Press Enter to close` yazarsa Enter'a bas. **Boyut, bilinmeyen dosya türü veya flag bulunamadı uyarısı varsa devam etmeyi onaylama; dur.** Küçük RAW preloader dosyası bu araca uygun değildir.

Oluşan dosya: `mtkclient/preloader_path/ufs-boot1-patched.bin`.

```bash
wc -c preloader_path/ufs-boot1-patched.bin
```

**Kontrol:** Çıktı yine **4194304** bayt olmalı. Boyut kontrolü tek başına dosyanın güvenli olduğunu kanıtlamaz. Araç aynı adlı çıktının üzerine yazabilir; özgün yedeği `preloader_path/` içinde tutma.

## 5. BOOT1'e yaz ve kontrol et

**Bu adım telefonu değiştirir.** Yedeklerin başka diskte de olduğundan emin ol. Bu cihazda A/B bölüm düzeni yoktu ve yalnız BOOT1 yazıldı. A/B düzeni olan cihazda burada dur.

Önce telefondaki BOOT1'i tekrar oku:

```bash
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-before-write.bin --parttype boot1
cmp backup/ufs-boot1-original.bin backup/ufs-boot1-before-write.bin && echo "TAMAM: özgün yedek eşleşiyor"
```

**Kontrol:** `TAMAM` mesajı görünmeli. Fark veya hata varsa devam etme.

Değiştirilmiş dosyayı yaz:

```bash
./.venv/bin/python mtk.py wf preloader_path/ufs-boot1-patched.bin --parttype boot1
```

Yazma başarılıysa geri oku ve karşılaştır:

```bash
./.venv/bin/python mtk.py ro 0 0x400000 backup/ufs-boot1-after-write.bin --parttype boot1
cmp preloader_path/ufs-boot1-patched.bin backup/ufs-boot1-after-write.bin && echo "TAMAM: yazılan dosya eşleşiyor"
```

**Kontrol:** Yazma ve okuma başarılı olmalı; `TAMAM` mesajı görünmeli. **Hata veya fark varsa telefonu yeniden başlatma.** [Geri dönüş notlarını oku](docs/TECHNICAL-NOTES.tr.md#sorunlar-ve-geri-dönüş-sınırı). BOOT2'ye yazma.

## 6. Telefonu aç ve kilidi kaldır

Geri okuma eşleştiyse:

```bash
./.venv/bin/python mtk.py reset
```

USB'yi çıkar ve Android'in açılmasını bekle. Sonra USB'yi yeniden bağla; telefondaki USB hata ayıklama izin ekranını onayla.

```bash
adb reboot bootloader
fastboot devices
```

**Kontrol:** `fastboot devices` bir cihaz satırı göstermeli. Liste boşsa devam etme. Ekrandaki `fastboot unlock verify ok` mesajı tek başına kilidin açıldığını göstermez.

**Sıradaki komut kişisel verileri siler:**

```bash
fastboot flashing unlock
```

Telefondaki onay ekranını oku ve ekranda belirtilen ses tuşuyla onayla. İşlem başarılıysa:

```bash
fastboot reboot
```

## 7. Kilidin açıldığını doğrula

Telefonun ilk kurulumunu tamamla. USB hata ayıklamayı yeniden aç ve bilgisayarın bağlantısına izin ver.

```bash
adb shell getprop ro.boot.flash.locked
adb shell getprop ro.boot.vbmeta.device_state
adb shell getprop ro.boot.verifiedbootstate
```

Beklenen sonuçlar, komut sırasıyla:

| Komutun sonundaki özellik | Beklenen çıktı |
| --- | --- |
| `ro.boot.flash.locked` | `0` |
| `ro.boot.vbmeta.device_state` | `unlocked` |
| `ro.boot.verifiedbootstate` | `orange` |

Üç sonuç da eşleşiyorsa kilit açılması doğrulanmış olur. Boş veya farklı sonuç varsa işlemi başarılı sayma. Kilit açılması doğrulanmadan GSI veya değiştirilmiş vbmeta yazma. Bu rehber ROM kurulumunu kapsamaz.

## Dosyalar nerede?

| Dosya / klasör | Ne işe yarar? |
| --- | --- |
| `README.md` | İngilizce adım adım rehber |
| `README.tr.md` | Bu Türkçe rehber |
| `README.en.md` | İngilizce özet |
| `docs/TECHNICAL-NOTES.md` | İngilizce teknik notlar |
| `docs/TECHNICAL-NOTES.tr.md` | Deneyim, kaynaklar ve geri dönüş sınırları |
| `tools/` | Hazır araç paketi, patch kodu ve lisanslar |
| `SHA256SUMS` | Dahil edilen araçların bütünlük kontrolü |
| `mtkclient/backup/` | Kurulumdan sonra senin aldığın özgün yedekler |
| `mtkclient/preloader_path/` | Senin yedeğinden oluşturulan değiştirilmiş dosya |

Depoda telefondan alınmış firmware veya kişisel yedek yoktur. Her kullanıcı kendi yedeğini kullanır. Yöntem ve araçlar [Shocked-Cat](https://github.com/Shocked-Cat/oppo-mtk-fastboot-unlock) ve [bkerler/mtkclient](https://github.com/bkerler/mtkclient) projelerine aittir; sürüm ve lisans bilgileri [teknik notlarda](docs/TECHNICAL-NOTES.tr.md) korunmuştur.

Cihazın açılmaz hâle gelmesi, veri kaybı veya başka zararlar için sorumluluk kabul edilmez. İşlemleri kendi sorumluluğunda uygula. Rehber metni [CC BY 4.0](LICENSE), araçlar kendi lisansları altında paylaşılır.
