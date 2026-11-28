#!/bin/bash
# ==============================================================================
# MELES OS: İNTERAKTİF SİSTEM TURU (MELES TOUR)
# Standart: Saf Bash + YAD/GTK3 | Tam Koyu Tema | Hızlı Uygulama Başlatıcılı
# ==============================================================================

export GTK_THEME="Adwaita:dark"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BELGELER_DIR="$SCRIPT_DIR/belgeler"

ADIM=1
TOPLAM_ADIM=5

while true; do
    case $ADIM in
        1)
            BASLIK="1. Masaüstü ve Görev Çubuğu (Panel)"
            ICERIK="<span font='26' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES OS TURU (1/5)</b></span>\n\n<span font='12' weight='bold' color='#38bdf8'>Masaüstü ve Kolay Erişim:</span>\n\n• Ekranın altındaki görev çubuğu üzerinden açık uygulamalarınızı yönetebilirsiniz.\n• Sol alt köşeden uygulama menüsüne erişebilir, sağ alt köşeden ses, ağ ve saat durumunu kontrol edebilirsiniz.\n• Panel konumunu dilediğiniz zaman <b>İnce Ayar</b> menüsünden değiştirebilirsiniz."
            BUTONLAR=(
                --button="Paneli Özelleştir:3"
                --button="İleri:0"
                --button="Turu Kapat:1"
            )
            ;;
        2)
            BASLIK="2. Kurulu Uygulamalar ve Araçlar"
            ICERIK="<span font='26' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES OS TURU (2/5)</b></span>\n\n<span font='12' weight='bold' color='#38bdf8'>Zengin ve Hazır Yazılım Ekosistemi:</span>\n\n• İnternet tarayıcısı, dosya yöneticisi, metin editörü ve medya oynatıcı sisteminizde hazır gelir.\n• <b>Meles Araçlar Merkezi</b> üzerinden tüm kurulu programları tek bir ekranda görebilir ve aratabilirsiniz.\n• İhtiyacınız olan yeni programları tek tıkla sistem paket depolarından yükleyebilirsiniz."
            BUTONLAR=(
                --button="Uygulamalar Merkezini Aç:3"
                --button="Geri:2"
                --button="İleri:0"
                --button="Turu Kapat:1"
            )
            ;;
        3)
            BASLIK="3. İnce Ayar ve Görsel Temalar"
            ICERIK="<span font='26' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES OS TURU (3/5)</b></span>\n\n<span font='12' weight='bold' color='#38bdf8'>Sisteminizi Zevkinize Göre Özelleştirin:</span>\n\n• <b>Meles İnce Ayar</b> menüsünden Titanium Koyu veya Obsidian Saf Siyah temaya tek tıkla geçiş yapabilirsiniz.\n• Ekran parlaklığı, çözünürlük, HiDPI ölçekleme ve kompozitör efektlerini kontrol edebilirsiniz.\n• Süper (Windows) tuşunun işlevini dilediğiniz başlatıcıya bağlayabilirsiniz."
            BUTONLAR=(
                --button="İnce Ayar ve Temaları Aç:3"
                --button="Geri:2"
                --button="İleri:0"
                --button="Turu Kapat:1"
            )
            ;;
        4)
            BASLIK="4. Donanım, Bakım ve Yedekleme"
            ICERIK="<span font='26' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES OS TURU (4/5)</b></span>\n\n<span font='12' weight='bold' color='#38bdf8'>Tam Kontrol ve Güvenlik:</span>\n\n• <b>Timeshift</b> entegrasyonu ile tek tıkla anlık sistem geri yükleme noktası oluşturabilirsiniz.\n• <b>BleachBit & Temizlik</b> aracıyla gereksiz sistem önbelleğini ve çöpleri boşaltabilirsiniz.\n• Disk biçimlendirme (GParted) ve başlangıç onarım araçları her an elinizin altındadır."
            BUTONLAR=(
                --button="Bakım ve Yedek Araçlarını Aç:3"
                --button="Geri:2"
                --button="İleri:0"
                --button="Turu Kapat:1"
            )
            ;;
        5)
            BASLIK="5. Meles OS'i Keşfetmeye Hazırsınız!"
            ICERIK="<span font='26' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES OS TURU (5/5)</b></span>\n\n<span font='12' weight='bold' color='#38bdf8'>Aramıza Hoş Geldiniz:</span>\n\n• Sistem belgelerini incelemek için Karşılama Merkezindeki <b>Kılavuz</b> ve <b>Meles Nedir?</b> seçeneklerini kullanabilirsiniz.\n• Topluluğa katılmak için <b>Discord</b> ve <b>GitHub</b> bağlantılarını ziyaret edebilirsiniz.\n\nKeyifli ve verimli kullanımlar dileriz!"
            BUTONLAR=(
                --button="Kılavuzu Aç:3"
                --button="Geri:2"
                --button="Turu Bitir:0"
            )
            ;;
    esac

    yad --form \
        --title="Meles OS - $BASLIK" \
        --width=640 --height=430 --center \
        --text="$ICERIK\n" \
        "${BUTONLAR[@]}"

    SECIM=$?

    # İlgili Aracı Başlat Butonu (Kod: 3)
    if [ $SECIM -eq 3 ]; then
        case $ADIM in
            1|3)
                [ -f "$SCRIPT_DIR/meles_ince_ayar.sh" ] && bash "$SCRIPT_DIR/meles_ince_ayar.sh" &
                ;;
            2|4)
                [ -f "$SCRIPT_DIR/meles_araclar.sh" ] && bash "$SCRIPT_DIR/meles_araclar.sh" &
                ;;
            5)
                xdg-open "$BELGELER_DIR/Kılavuz.odt" 2>/dev/null &
                ;;
        esac
        continue
    # İleri / Bitir Butonu (Kod: 0)
    elif [ $SECIM -eq 0 ]; then
        if [ $ADIM -ge $TOPLAM_ADIM ]; then
            break
        else
            ADIM=$((ADIM + 1))
        fi
    # Geri Butonu (Kod: 2)
    elif [ $SECIM -eq 2 ]; then
        if [ $ADIM -gt 1 ]; then
            ADIM=$((ADIM - 1))
        fi
    # Çıkış / Kapat (Kod: 1, 252 vb.)
    else
        break
    fi
done

exit 0
