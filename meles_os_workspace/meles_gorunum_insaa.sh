#!/bin/bash
# ==============================================================================
# MELES OS KONTROL MERKEZİ (SAF BASH + GELİŞMİŞ NATIVE ARAYÜZ V3)
# ==============================================================================
export SCRIPT_PATH="$(realpath "$0")"

# YAD Kontrolü
if ! command -v yad &> /dev/null; then
    echo "Hata: YAD yüklü değil. 'sudo apt install yad' çalıştırın."
    exit 1
fi

export GTK_THEME="Yaru-blue-dark"
PENCERE_BASLIK="Meles OS Ayarlar"
IKON="preferences-system"

# ==============================================================================
# BUTON AKSİYONLARI (KENDİ KENDİNİ ÇAĞIRAN BASH FONKSİYONLARI)
# ==============================================================================
if [ "$1" == "--ext-info" ]; then
    (
        echo "========================================="
        echo "          GENİŞ SİSTEM DONANIM RAPORU"
        echo "========================================="
        echo -e "\n>>> İŞLEMCİ (CPU) DETAYLARI:"
        lscpu | egrep 'Model name|Socket|Thread|CPU\(s\)|MHz'
        echo -e "\n>>> BELLEK (RAM & SWAP) DURUMU:"
        free -h
        echo -e "\n>>> DİSK KULLANIM ORANLARI:"
        df -h -t ext4 -t btrfs -t vfat -t ntfs
        echo -e "\n>>> ÇEKİRDEK (KERNEL) SÜRÜMÜ:"
        uname -rm
    ) > /tmp/genis_bilgi.txt
    yad --text-info --title="Geniş Sistem Raporu" --filename="/tmp/genis_bilgi.txt" \
        --width=700 --height=500 --fontname="Ubuntu Mono 11" --button="Kapat:0" --center
    exit 0

elif [ "$1" == "--set-theme" ]; then
    DEGERLER=$(yad --form --title="Görünüm Teması" --width=400 --center \
        --text="Sistem renklerini ve buton düzenini seçin:" \
        --field="Renk Modu:CB" "Koyu (Dark)!Açık (Light)" \
        --field="Pencere Butonları:CB" "Windows Stili (Sağda)!macOS Stili (Solda)" \
        --button="Uygula:0" --button="İptal:1")
    if [ $? -eq 0 ]; then
        MOD=$(echo "$DEGERLER" | awk -F'|' '{print $1}')
        BTN=$(echo "$DEGERLER" | awk -F'|' '{print $2}')
        
        if [ "$MOD" == "Koyu (Dark)" ]; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
            gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-blue-dark'
        else
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
            gsettings set org.gnome.desktop.interface gtk-theme 'Yaru-blue'
        fi
        
        if [ "$BTN" == "Windows Stili (Sağda)" ]; then
            gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
        else
            gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
        fi
        yad --info --text="Tema başarıyla uygulandı!" --center --timeout=2 --no-buttons
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
    pkexec bash -c "apt-get clean && apt-get install -f -y && dpkg --configure -a && apt-get autoremove -y"
    yad --info --text="Önbellek temizlendi ve kırık paketler onarıldı." --center --timeout=3 --no-buttons
    exit 0

elif [ "$1" == "--perf-mode" ]; then
    SECIM=$(yad --list --title="İşlemci Modu" --center --width=350 --height=200 \
        --column="Mod" "🔥 Yüksek Performans (Oyun/Render)" "🔋 Güç Tasarrufu (Pil)")
    if [ -n "$SECIM" ]; then
        if [[ "$SECIM" == *"Yüksek"* ]]; then
            pkexec bash -c "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            yad --info --text="İşlemciler maksimum frekansa kilitlendi!" --center --timeout=2 --no-buttons
        else
            pkexec bash -c "echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            yad --info --text="İşlemciler güç tasarruf moduna alındı." --center --timeout=2 --no-buttons
        fi
    fi
    exit 0
fi

# ==============================================================================
# ANA ARAYÜZ MOTORU (SOL MENÜLÜ "GNOME SETTINGS" KLONU)
# ==============================================================================
KEY=$RANDOM

# TAB 1: SİSTEM BİLGİSİ (Sağ İçerik)
yad --plug=$KEY --tabnum=1 --form \
    --text="<span font='16' weight='bold'>Sistem Durumu</span>\nİşletim sistemi ve donanım özetiniz." \
    --field="Meles OS Versiyon:":RO "2026.08-TITANIUM" \
    --field="Arayüz:":RO "GNOME Dash-To-Panel" \
    --field="Mimar:":RO "x86_64 / amd64" \
    --field="Donanım Raporunu Görüntüle:FBTN" "$SCRIPT_PATH --ext-info" \
    &

# TAB 2: KİŞİSELLEŞTİRME (Sağ İçerik)
yad --plug=$KEY --tabnum=2 --form \
    --text="<span font='16' weight='bold'>Kişiselleştirme</span>\nArayüzü, temaları ve görev çubuğunu ayarlayın." \
    --field="Tema ve Pencere Renklerini Değiştir:FBTN" "$SCRIPT_PATH --set-theme" \
    --field="Görev Çubuğu (Panel) Ayarları:FBTN" "$SCRIPT_PATH --set-panel" \
    --field="Açılış (Boot) Ekranı Özelleştirme:FBTN" "$SCRIPT_PATH --boot-opts" \
    &

# TAB 3: UYGULAMA YÖNETİCİSİ (Sağ İçerik)
yad --plug=$KEY --tabnum=3 --form \
    --text="<span font='16' weight='bold'>Uygulama İzinleri ve Yönetimi</span>\nMeles özel araçlarını veya sistem uygulamalarını kontrol edin." \
    --field="Sistemdeki Tüm Uygulamaları Yönet (Dondur/Kaldır):FBTN" "$SCRIPT_PATH --all-apps" \
    --field="Meles Özel Araçlarını Seçerek Sil:FBTN" "$SCRIPT_PATH --remove-meles-apps" \
    &

# TAB 4: BAKIM VE PERFORMANS (Sağ İçerik)
yad --plug=$KEY --tabnum=4 --form \
    --text="<span font='16' weight='bold'>Motor, Bakım ve Onarım</span>\nSistem sağlığını koruyun ve performansı artırın." \
    --field="Oyun ve Performans Modu (CPU Ayarı):FBTN" "$SCRIPT_PATH --perf-mode" \
    --field="Sistemi Onar ve Önbelleği Temizle:FBTN" "$SCRIPT_PATH --sys-repair" \
    &

# NİHAİ PENCERE YARATICISI (Menüyü sola, içerikleri sağa yerleştirir)
yad --notebook --key=$KEY --tab-pos=left \
    --title="Meles OS Ayarlar" --width=850 --height=500 --window-icon="$IKON" \
    --tab="Hakkında" \
    --tab="Görünüm" \
    --tab="Uygulamalar" \
    --tab="Sistem Bakım" \
    --button="Kapat:0"

exit 0
