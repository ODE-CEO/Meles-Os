#!/bin/bash
# ==============================================================================
# MELES OS KONTROL MERKEZİ (ULTIMATE V5 - DEVASA SİSTEM VE TEMA MOTORU)
# ==============================================================================
export SCRIPT_PATH="$(command -v meles-ayarlar 2>/dev/null || realpath "$0")"

# Gerekli Paketlerin Kontrolü
if ! command -v yad &> /dev/null; then
    echo "Hata: YAD yüklü değil. 'sudo apt install yad' çalıştırın."
    exit 1
fi

export GTK_THEME="Yaru-blue-dark"
PENCERE_BASLIK="Meles OS Kontrol Merkezi"
IKON="preferences-system"

# ==============================================================================
# BUTON AKSİYONLARI (MOTORLAR VE FONKSİYONLAR)
# ==============================================================================

if [ "$1" == "--ext-info" ]; then
    (
        echo "========================================="
        echo "          MELES OS DETAYLI RAPOR"
        echo "========================================="
        echo -e "\n>>> İŞLEMCİ (CPU):"
        lscpu | egrep 'Model name|Socket|Thread|CPU\(s\)|MHz'
        echo -e "\n>>> BELLEK (RAM) VE TAKAS (SWAP):"
        free -h
        echo -e "\n>>> DEPOLAMA (DİSK) DURUMU:"
        df -h -t ext4 -t btrfs -t vfat -t ntfs
        echo -e "\n>>> AĞ BAĞDAŞTIRICILARI:"
        ip -brief address
        echo -e "\n>>> ÇEKİRDEK (KERNEL):"
        uname -a
        echo -e "\n>>> USB CİHAZLAR:"
        lsusb
    ) > /tmp/genis_bilgi.txt
    yad --text-info --title="Geniş Sistem Raporu" --filename="/tmp/genis_bilgi.txt" \
        --width=750 --height=550 --fontname="Ubuntu Mono 11" --button="Kapat:0" --center
    exit 0

elif [ "$1" == "--sys-update" ]; then
    yad --info --title="Güncelleme Yöneticisi" --text="Sistem güncellemeleri kontrol edilecek.\nBu işlem bir terminal penceresinde açılacaktır." --center --timeout=3 --no-buttons
    # Sistemin gerçek zamanlı güncellenmesi için terminal açılır
    gnome-terminal -- bash -c "echo '>>> Meles OS Sistem Güncelleyici Başlatılıyor...'; sudo apt update; sudo apt upgrade -y; sudo apt autoremove -y; echo 'Güncelleme Tamamlandı! Çıkmak için ENTER a basın.'; read"
    exit 0

elif [ "$1" == "--flatpak-update" ]; then
    gnome-terminal -- bash -c "echo '>>> Flatpak Uygulamaları Güncelleniyor...'; flatpak update -y; echo 'Tamamlandı! Çıkmak için ENTER a basın.'; read"
    exit 0

# ------------------------------------------------------------------------------
# YENİ EKLENEN DEVASA MODÜL: GELİŞMİŞ TEMA, ARKA PLAN VE RENK MOTORU
# ------------------------------------------------------------------------------
elif [ "$1" == "--advanced-theme" ]; then
    DEGERLER=$(yad --form --title="Temalar ve Renk Yönetimi" --width=520 --center \
        --text="Sistem arka planını ve pencere renklerini detaylıca özelleştirin:" \
        --field="Arka Plan Tipi:CB" "Meles Varsayılan (Resim)!Saf Siyah (OLED Modu)!Saf Beyaz!Koyu Gri (Matrix)" \
        --field="Pencere Vurgu Rengi:CB" "Mavi (Varsayılan)!Kırmızı!Yeşil!Turuncu!Mor" \
        --field="Karanlık/Aydınlık Mod:CB" "Karanlık (Dark)!Aydınlık (Light)" \
        --button="Temayı Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ]; then
        ARKA_PLAN=$(echo "$DEGERLER" | awk -F'|' '{print $1}')
        VURGU=$(echo "$DEGERLER" | awk -F'|' '{print $2}')
        MOD=$(echo "$DEGERLER" | awk -F'|' '{print $3}')

        # 1. ARKA PLAN AYARLAYICI (Duvar Kağıdı vs. Düz Renk)
        if [ "$ARKA_PLAN" == "Saf Siyah (OLED Modu)" ]; then
            gsettings set org.gnome.desktop.background picture-uri ''
            gsettings set org.gnome.desktop.background picture-uri-dark ''
            gsettings set org.gnome.desktop.background primary-color '#000000'
        elif [ "$ARKA_PLAN" == "Saf Beyaz" ]; then
            gsettings set org.gnome.desktop.background picture-uri ''
            gsettings set org.gnome.desktop.background picture-uri-dark ''
            gsettings set org.gnome.desktop.background primary-color '#FFFFFF'
        elif [ "$ARKA_PLAN" == "Koyu Gri (Matrix)" ]; then
            gsettings set org.gnome.desktop.background picture-uri ''
            gsettings set org.gnome.desktop.background picture-uri-dark ''
            gsettings set org.gnome.desktop.background primary-color '#1a1b26'
        else
            # Varsayılan Meles Arka Planına Geri Dön
            gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/meles/arkaplan5.png'
            gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/meles/arkaplan5.png'
        fi

        # 2. PENCERE VURGU RENGİ (GTK Tema Entegrasyonu)
        THEME_BASE="Yaru-blue"
        if [ "$VURGU" == "Kırmızı" ]; then THEME_BASE="Yaru-red"; fi
        if [ "$VURGU" == "Yeşil" ]; then THEME_BASE="Yaru-olive"; fi
        if [ "$VURGU" == "Turuncu" ]; then THEME_BASE="Yaru-bark"; fi
        if [ "$VURGU" == "Mor" ]; then THEME_BASE="Yaru-magenta"; fi

        # 3. KARANLIK / AYDINLIK MOD ENTEGRASYONU
        if [ "$MOD" == "Karanlık (Dark)" ]; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            gsettings set org.gnome.desktop.interface gtk-theme "${THEME_BASE}-dark"
        else
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            gsettings set org.gnome.desktop.interface gtk-theme "${THEME_BASE}"
        fi

        yad --info --text="Arka plan ve pencere renkleri başarıyla değiştirildi!\nMeles OS yepyeni bir görünüme kavuştu." --center --timeout=3 --no-buttons
    fi
    exit 0

elif [ "$1" == "--set-theme" ]; then
    DEGERLER=$(yad --form --title="İkon ve Buton Düzeni" --width=450 --center \
        --text="Sistem ikonlarını ve pencere butonlarını ayarlayın:" \
        --field="Pencere Butonları:CB" "Windows Stili (Sağda)!macOS Stili (Solda)" \
        --field="İkon Paketi:CB" "Papirus-Dark!Papirus!Yaru" \
        --button="Uygula:0" --button="İptal:1")
    if [ $? -eq 0 ]; then
        BTN=$(echo "$DEGERLER" | awk -F'|' '{print $1}')
        IKN=$(echo "$DEGERLER" | awk -F'|' '{print $2}')

        if [ "$BTN" == "Windows Stili (Sağda)" ]; then
            gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
        else
            gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
        fi

        gsettings set org.gnome.desktop.interface icon-theme "$IKN"
        yad --info --text="Buton düzeni ve ikon paketi uygulandı!" --center --timeout=2 --no-buttons
    fi
    exit 0

elif [ "$1" == "--font-scale" ]; then
    MEVCUT_OLCEK=$(gsettings get org.gnome.desktop.interface text-scaling-factor)
    YENI_OLCEK=$(yad --scale --title="Yazı Tipi Boyutu (Ölçekleme)" --width=400 --center \
        --text="Sistem genelindeki yazı tipi boyutunu ayarlayın (Varsayılan: 1.00)" \
        --value="${MEVCUT_OLCEK}" --min-value="0.75" --max-value="1.50" --step="0.05" \
        --button="Uygula:0" --button="İptal:1")
    if [ $? -eq 0 ] && [ -n "$YENI_OLCEK" ]; then
        gsettings set org.gnome.desktop.interface text-scaling-factor "$YENI_OLCEK"
        yad --info --text="Ölçekleme $YENI_OLCEK olarak ayarlandı!" --center --timeout=2 --no-buttons
    fi
    exit 0

elif [ "$1" == "--set-panel" ]; then
    MEVCUT_BOYUT=$(dconf read /org/gnome/shell/extensions/dash-to-panel/panel-size || echo "46")
    MEVCUT_OPAKLIK=$(dconf read /org/gnome/shell/extensions/dash-to-panel/trans-panel-opacity || echo "0.9")
    OPAKLIK_YUZDE=$(echo "$MEVCUT_OPAKLIK * 100" | bc | cut -d'.' -f1)

    DEGERLER=$(yad --form --title="Görev Çubuğu Ayarları" --width=450 --center \
        --text="Görev çubuğu (Panel) detaylarını özelleştirin:" \
        --field="Konum:CB" "BOTTOM!TOP!LEFT!RIGHT" \
        --field="Yükseklik (px):NUM" "$MEVCUT_BOYUT!30..80!1" \
        --field="Şeffaflık (%):NUM" "${OPAKLIK_YUZDE:-100}!0..100!5" \
        --field="Otomatik Gizle:CHK" "FALSE" \
        --button="Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ]; then
        KONUM=$(echo "$DEGERLER" | awk -F'|' '{print $1}')
        YUKSEKLIK=$(echo "$DEGERLER" | awk -F'|' '{print $2}' | cut -d',' -f1)
        SEFFAFLIK=$(echo "$DEGERLER" | awk -F'|' '{print $3}' | cut -d',' -f1)
        GIZLE=$(echo "$DEGERLER" | awk -F'|' '{print $4}')

        OPACITY_VAL=$(echo "scale=2; $SEFFAFLIK / 100" | bc)
        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-position "'$KONUM'"
        dconf write /org/gnome/shell/extensions/dash-to-panel/panel-size "$YUKSEKLIK"
        dconf write /org/gnome/shell/extensions/dash-to-panel/trans-use-custom-opacity true
        dconf write /org/gnome/shell/extensions/dash-to-panel/trans-panel-opacity "$OPACITY_VAL"

        if [ "$GIZLE" == "TRUE" ]; then
            dconf write /org/gnome/shell/extensions/dash-to-panel/intellihide true
        else
            dconf write /org/gnome/shell/extensions/dash-to-panel/intellihide false
        fi
        yad --info --text="Görev Çubuğu güncellendi!" --center --timeout=2 --no-buttons
    fi
    exit 0

elif [ "$1" == "--perf-mode" ]; then
    SECIM=$(yad --list --title="İşlemci Modu" --center --width=400 --height=220 \
        --text="İşlemci (CPU) frekans yöneticisini ayarlayın:" \
        --column="Mod" "🔥 Yüksek Performans (Oyun/Render)" "🔋 Güç Tasarrufu (Pil/Sessiz)" "⚖️ Dengeli (Otomatik)")
    if [ -n "$SECIM" ]; then
        if [[ "$SECIM" == *"Yüksek"* ]]; then
            pkexec bash -c "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            yad --info --text="İşlemciler maksimum frekansa kilitlendi!" --center --timeout=2 --no-buttons
        elif [[ "$SECIM" == *"Tasarruf"* ]]; then
            pkexec bash -c "echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            yad --info --text="İşlemciler güç tasarruf moduna alındı." --center --timeout=2 --no-buttons
        else
            pkexec bash -c "echo schedutil | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            yad --info --text="İşlemciler dengeli moda (otomatik) alındı." --center --timeout=2 --no-buttons
        fi
    fi
    exit 0

elif [ "$1" == "--clear-ram" ]; then
    yad --info --text="Sistem RAM önbelleği (Cache/Buffer) temizleniyor...\nLütfen bekleyin." --center --timeout=2 --no-buttons
    pkexec bash -c "sync; echo 3 > /proc/sys/vm/drop_caches; swapoff -a && swapon -a"
    yad --info --text="RAM ve Takas Alanı başarıyla temizlendi!\nSistem rahatlatıldı." --center --timeout=3 --no-buttons
    exit 0

elif [ "$1" == "--swap-tune" ]; then
    MEVCUT_SWAP=$(cat /proc/sys/vm/swappiness)
    YENI_SWAP=$(yad --scale --title="Swappiness (Disk Kullanım Eğilimi)" --width=400 --center \
        --text="RAM dolmadan diske yazma oranını belirleyin.\nOyunlar için düşük (10), sunucular için yüksek (60) önerilir.\nMevcut: $MEVCUT_SWAP" \
        --value="$MEVCUT_SWAP" --min-value="0" --max-value="100" --step="5" \
        --button="Uygula:0" --button="İptal:1")
    if [ $? -eq 0 ] && [ -n "$YENI_SWAP" ]; then
        pkexec bash -c "sysctl vm.swappiness=$YENI_SWAP; sed -i '/^vm.swappiness=/d' /etc/sysctl.conf; echo 'vm.swappiness=$YENI_SWAP' >> /etc/sysctl.conf"
        yad --info --text="Swappiness kalıcı olarak $YENI_SWAP yapıldı!" --center --timeout=2 --no-buttons
    fi
    exit 0

elif [ "$1" == "--net-reset" ]; then
    pkexec bash -c "systemctl restart NetworkManager; resolvectl flush-caches"
    yad --info --text="Ağ bağdaştırıcısı ve DNS önbelleği sıfırlandı.\nİnternet bağlantınız tazelendi." --center --timeout=3 --no-buttons
    exit 0

elif [ "$1" == "--fw-toggle" ]; then
    DURUM=$(sudo ufw status | grep -i "Status: active")
    if [ -n "$DURUM" ]; then
        pkexec ufw disable
        yad --info --text="Güvenlik Duvarı (Firewall) KAPATILDI." --center --timeout=2 --no-buttons
    else
        pkexec bash -c "ufw default deny incoming; ufw default allow outgoing; ufw enable"
        yad --info --text="Güvenlik Duvarı (Firewall) AKTİFLEŞTİRİLDİ!\nDışarıdan gelen izinsiz bağlantılar engellenecek." --center --timeout=3 --no-buttons
    fi
    exit 0

elif [ "$1" == "--remove-meles-apps" ]; then
    SECILEN=$(yad --list --checklist --title="Meles Araçlarını Sil" \
        --width=600 --height=350 --center --window-icon="system-software-install" \
        --text="Kaldırmak istediğiniz özel Meles uygulamalarını seçin:" \
        --column="Seç" --column="Uygulama Adı" --column="Açıklama" \
        FALSE "Meles Browser" "Hafif ve Hızlı İnternet Tarayıcısı" \
        FALSE "Meles Hızlı Yükleyici" "Terminal tabanlı yazılım kurucu" \
        FALSE "Meles Kurulum" "İşletim Sistemi Diske Yükleme Aracı" \
        --button="Seçilenleri Kökten Sil:0" --button="İptal:1")

    if [ $? -eq 0 ] && [ -n "$SECILEN" ]; then
        if [[ "$SECILEN" == *"Meles Browser"* ]]; then
            pkexec bash -c "rm -f /usr/local/bin/melesbrowser.py /etc/skel/Desktop/Meles_Browser.desktop ~/Masaüstü/Meles_Browser.desktop ~/Desktop/Meles_Browser.desktop"
        fi
        if [[ "$SECILEN" == *"Meles Hızlı Yükleyici"* ]]; then
            pkexec bash -c "rm -f /usr/local/bin/meles-hizli-yukleyici.sh /etc/skel/Desktop/Meles_Hizli*.desktop ~/Masaüstü/Meles_Hizli*.desktop"
        fi
        if [[ "$SECILEN" == *"Meles Kurulum"* ]]; then
            pkexec bash -c "rm -f /usr/local/bin/meleskurulum.sh /etc/skel/Desktop/Meles_OS_Kur.desktop ~/Masaüstü/Meles_OS_Kur.desktop"
        fi
        yad --info --text="Seçilen Meles araçları sistemden tamamen kazındı!" --center --timeout=2 --no-buttons
    fi
    exit 0

elif [ "$1" == "--all-apps" ]; then
    APP_LIST=""
    while IFS= read -r f; do
        NAME=$(grep -m 1 "^Name=" "$f" | cut -d= -f2 | tr -d '"' | tr -d "'")
        EXEC=$(grep -m 1 "^Exec=" "$f" | cut -d= -f2 | awk '{print $1}' | rev | cut -d/ -f1 | rev)
        if [ -n "$NAME" ] && [ -n "$EXEC" ]; then
            APP_LIST="$APP_LIST FALSE \"$NAME\" \"$EXEC\""
        fi
    done < <(find /usr/share/applications -name "*.desktop" 2>/dev/null)

    SECILEN=$(echo $APP_LIST | xargs yad --list --checklist --title="Tüm Uygulamalar" \
        --width=650 --height=500 --center --window-icon="system-users" \
        --text="Bilgisayardaki tüm grafiksel uygulamalar. Birden fazla seçebilirsiniz:" \
        --column="Seç" --column="Uygulama Adı" --column="Sistem Kodu" \
        --button="İleri (İşlem Seç):0" --button="İptal:1")

    if [ $? -eq 0 ] && [ -n "$SECILEN" ]; then
        ACTION=$(yad --list --title="İşlem Seçimi" --center --width=450 --height=250 \
            --text="Seçili uygulamalara ne yapılmasını istiyorsunuz?" \
            --column="İşlem" --column="Açıklama" \
            "KÖKTEN SİL" "Uygulamayı ve artık dosyalarını (Purge) kaldırır" \
            "DONDUR" "Diskte kalır ama çalışması işletim sistemince engellenir" \
            "ÇÖZ" "Dondurulmuş uygulamanın kilidini açar" \
            --button="Uygula:0" --button="İptal:1")
            
        if [ -n "$ACTION" ]; then
            ACT_CODE=$(echo "$ACTION" | awk -F'|' '{print $1}')
            APPS_TO_PROCESS=$(echo "$SECILEN" | grep "^TRUE|" | awk -F'|' '{print $3}')
            for APP in $APPS_TO_PROCESS; do
                if [ "$ACT_CODE" == "KÖKTEN SİL" ]; then
                    pkexec apt-get purge -y "$APP"
                elif [ "$ACT_CODE" == "DONDUR" ]; then
                    APP_PATH=$(which "$APP")
                    if [ -n "$APP_PATH" ]; then pkexec chmod a-x "$APP_PATH"; fi
                elif [ "$ACT_CODE" == "ÇÖZ" ]; then
                    APP_PATH=$(which "$APP")
                    if [ -n "$APP_PATH" ]; then pkexec chmod a+x "$APP_PATH"; fi
                fi
            done
            yad --info --text="İşlem başarıyla tamamlandı!" --center --timeout=2 --no-buttons
        fi
    fi
    exit 0

elif [ "$1" == "--sys-repair" ]; then
    yad --info --text="Sistem onarımı başlıyor... Lütfen şifrenizi girin." --center --timeout=2 --no-buttons
    pkexec bash -c "apt-get clean && apt-get autoclean && apt-get install -f -y && dpkg --configure -a && apt-get autoremove -y; journalctl --vacuum-time=3d"
    yad --info --text="Önbellek temizlendi, kırık paketler onarıldı ve eski sistem günlükleri (loglar) silindi." --center --timeout=4 --no-buttons
    exit 0

elif [ "$1" == "--boot-opts" ]; then
    DEGERLER=$(yad --form --title="Açılış (Boot) Özelleştirme" --width=450 --center \
        --text="Bilgisayarınızın açılış mekaniğini ayarlayın:" \
        --field="Açılış Menüsü Bekleme (Saniye):NUM" "5!0..30!1" \
        --field="Boot Modu:CB" "Animasyonlu (Sessiz)!Geliştirici (Yazılı Ekran)" \
        --button="Kök Yetkiyle Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ]; then
        TIMEOUT=$(echo "$DEGERLER" | awk -F'|' '{print $1}' | cut -d',' -f1)
        MOD=$(echo "$DEGERLER" | awk -F'|' '{print $2}')

        pkexec bash -c "
            sed -i \"s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=$TIMEOUT/\" /etc/default/grub;
            if [ \"$MOD\" == \"Animasyonlu (Sessiz)\" ]; then
                sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/' /etc/default/grub
            else
                sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/' /etc/default/grub
            fi
            update-grub
        "
        yad --info --text="Açılış ayarları değiştirildi. (Yeniden başlatmada geçerli olur)" --center --timeout=3 --no-buttons
    fi
    exit 0
fi

# ==============================================================================
# ANA ARAYÜZ MOTORU (SEKME SEKME GNOME SETTINGS KLONU)
# ==============================================================================
KEY=$RANDOM

# TAB 1: SİSTEM & GÜNCELLEME
yad --plug=$KEY --tabnum=1 --form \
    --text="<span font='16' weight='bold'>Sistem ve Güncellemeler</span>\nİşletim sistemi durumunu izleyin ve güncelleyin." \
    --field="Meles OS Sürümü:":RO "2026.08-TITANIUM" \
    --field="Mimari ve Taban:":RO "x86_64 / amd64" \
    --field="Donanım Raporunu Görüntüle:FBTN" "$SCRIPT_PATH --ext-info" \
    --field="Sistemi Güncelle (APT Upgrade):FBTN" "$SCRIPT_PATH --sys-update" \
    --field="Mağaza Uygulamalarını Güncelle (Flatpak):FBTN" "$SCRIPT_PATH --flatpak-update" \
    &

# TAB 2: TEMALAR VE KİŞİSELLEŞTİRME (YENİ GÜNCELLENDİ)
yad --plug=$KEY --tabnum=2 --form \
    --text="<span font='16' weight='bold'>Temalar ve Görünüm</span>\nArka plan, pencere renkleri ve ikonları ayarlayın." \
    --field="Temalar, Arka Plan ve Pencere Renkleri (YENİ):FBTN" "$SCRIPT_PATH --advanced-theme" \
    --field="Buton Düzeni ve İkon Paketi:FBTN" "$SCRIPT_PATH --set-theme" \
    --field="Görev Çubuğu (Panel) Ayarları:FBTN" "$SCRIPT_PATH --set-panel" \
    --field="Yazı Tipi ve Sistem Ölçeklemesi:FBTN" "$SCRIPT_PATH --font-scale" \
    &

# TAB 3: AĞ & GÜVENLİK
yad --plug=$KEY --tabnum=3 --form \
    --text="<span font='16' weight='bold'>Ağ ve Güvenlik</span>\nBağlantı sorunlarını giderin ve sistemi koruyun." \
    --field="Ağ Bağlantılarını ve DNS'i Sıfırla:FBTN" "$SCRIPT_PATH --net-reset" \
    --field="Güvenlik Duvarı (UFW) Aç / Kapat:FBTN" "$SCRIPT_PATH --fw-toggle" \
    &

# TAB 4: UYGULAMA YÖNETİMİ
yad --plug=$KEY --tabnum=4 --form \
    --text="<span font='16' weight='bold'>Uygulama İzinleri</span>\nMeles özel araçlarını veya sistem uygulamalarını kontrol edin." \
    --field="Tüm Uygulamaları Yönet (Dondur/Kaldır):FBTN" "$SCRIPT_PATH --all-apps" \
    --field="Meles Özel Araçlarını Seçerek Sil:FBTN" "$SCRIPT_PATH --remove-meles-apps" \
    &

# TAB 5: PERFORMANS & DONANIM
yad --plug=$KEY --tabnum=5 --form \
    --text="<span font='16' weight='bold'>Performans Motoru</span>\nDonanımınızı oyun ve render için en üst düzeye çıkarın." \
    --field="İşlemci (CPU) Güç Modunu Ayarla:FBTN" "$SCRIPT_PATH --perf-mode" \
    --field="RAM ve Önbelleği Zorla Temizle (Drop Caches):FBTN" "$SCRIPT_PATH --clear-ram" \
    --field="Disk Takas (Swappiness) Oranını Değiştir:FBTN" "$SCRIPT_PATH --swap-tune" \
    &

# TAB 6: BAKIM VE ONARIM
yad --plug=$KEY --tabnum=6 --form \
    --text="<span font='16' weight='bold'>Sistem Bakım Araçları</span>\nKırık paketleri onarın ve boot ekranını ayarlayın." \
    --field="Açılış (Boot/Grub) Ekranını Özelleştir:FBTN" "$SCRIPT_PATH --boot-opts" \
    --field="Sistemi Onar ve Çöpleri Temizle:FBTN" "$SCRIPT_PATH --sys-repair" \
    &

# NİHAİ PENCERE YARATICISI
yad --notebook --key=$KEY --tab-pos=left \
    --title="Meles OS Kontrol Merkezi" --width=850 --height=520 --window-icon="$IKON" \
    --tab="Sistem Durumu" \
    --tab="Temalar ve Görünüm" \
    --tab="Ağ ve Güvenlik" \
    --tab="Uygulamalar" \
    --tab="Performans" \
    --tab="Bakım ve Onarım" \
    --button="Kapat:0"

exit 0
