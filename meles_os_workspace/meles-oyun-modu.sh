#!/bin/bash
# ==============================================================================
# PROJE ADI: Meles OS Oyun Performans Arttırıcı (ULTIMATE GAMING EDITION)
# GELİŞTİRİCİ: Yağız & Kaan
# ==============================================================================
export SCRIPT_PATH="$(realpath "$0")"

if ! command -v yad &> /dev/null; then
    echo "Hata: YAD yüklü değil."
    exit 1
fi

export GTK_THEME="Yaru-blue-dark"
PENCERE_BASLIK="Meles Oyun Motoru"
IKON="input-gaming"

# ---------------------------------------------------------
# OYUN OPTİMİZASYON FONKSİYONLARI
# ---------------------------------------------------------

if [ "$1" == "--enable-cpu-max" ]; then
    pkexec bash -c "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor" 2>/dev/null || true
    yad --info --title="Meles Oyun Modu" --text="Oyun Önceliği Modu Aktif!\nİşlemciniz (CPU) tüm çekirdekleriyle tam güçte çalışmaya ayarlandı." --center --timeout=3 --no-buttons
    exit 0

elif [ "$1" == "--clear-background" ]; then
    KAPAT_SECIM=$(yad --list --checklist --title="Meles Görev Katili" \
        --text="Kapatmak istediğiniz arka plan uygulamalarını ve servisleri seçin (RAM'i boğmamak için):" \
        --column="Seç" --column="Servis Adı" --column="Açıklama" \
        FALSE "gnome-software" "Arka Plan Uygulama Mağazası Güncelleyicisi" \
        FALSE "tracker-miner-fs-3" "Dosya İndeksleme Servisi (Diski yorar)" \
        FALSE "fwupd" "Sistem/BIOS Güncelleme Denetleyicisi" \
        FALSE "cupsd" "Yazıcı Servisi (Oyun oynarken gereksizdir)" \
        FALSE "evolution-alarm-notify" "Takvim ve Arka Plan Bildirimleri" \
        FALSE "discord" "Arka Plandaki Discord İstemcisi" \
        FALSE "steam" "Arka Plandaki Steam İstemcisi" \
        FALSE "chrome" "Açık Kalan Google Chrome İşlemleri" \
        FALSE "firefox" "Açık Kalan Firefox İşlemleri" \
        --width=650 --height=400 --center --button="Seçilenleri Katlet:0" --button="İptal:1")
        
    if [ $? -eq 0 ] && [ -n "$KAPAT_SECIM" ]; then
        APPS_TO_PROCESS=$(echo "$KAPAT_SECIM" | grep "^TRUE|" | awk -F'|' '{print $2}')
        for APP in $APPS_TO_PROCESS; do
            if [ "$APP" = "cupsd" ] || [ "$APP" = "fwupd" ]; then
                pkexec systemctl stop "$APP" 2>/dev/null || true
            else
                killall -9 "$APP" 2>/dev/null || true
            fi
        done
        pkexec bash -c "sync; echo 3 > /proc/sys/vm/drop_caches"
        yad --info --title="Meles Oyun Modu" --text="Seçilen arka plan servisleri KAPANMIŞTIR.\nSistem RAM'i ve CPU başarıyla temizlendi!" --center --timeout=3 --no-buttons
    fi
    exit 0

elif [ "$1" == "--gamemode-start" ]; then
    gamemoded -t
    yad --info --title="Meles Oyun Modu" --text="Feral GameMode altyapısı arka planda tetiklendi.\nDestekleyen oyunlar artık bu modda çalışacak." --center --timeout=3 --no-buttons
    exit 0

elif [ "$1" == "--goverlay-open" ]; then
    goverlay &
    exit 0

elif [ "$1" == "--mesa-opengl-boost" ]; then
    pkexec bash -c "echo 'export MESA_GL_THREAD=true' >> /etc/environment; echo 'export vblank_mode=0' >> /etc/environment"
    yad --info --title="Meles Oyun Modu" --text="Mesa OpenGL Çoklu Çekirdek (Multi-Thread) desteği ve V-Sync Kilidi (Sınırsız FPS) aktifleştirildi.\nSistemi yeniden başlattığınızda geçerli olacaktır!" --center --timeout=4 --no-buttons
    exit 0
fi

# ---------------------------------------------------------
# ANA OYUN ARAYÜZÜ
# ---------------------------------------------------------
yad --form --title="$PENCERE_BASLIK" --width=550 --center \
    --window-icon="$IKON" \
    --text="<span font='16' weight='bold' foreground='#ef4444'>🔥 Meles Oyun ve Performans Motoru</span>\nDüşük sistemlerde FPS artışı sağlamak ve donanımınızı şahlandırmak için modları aktifleştirin.\n" \
    --field="İşlemci (CPU) Oyun Önceliği Modu (Maksimum Güç):FBTN" "$SCRIPT_PATH --enable-cpu-max" \
    --field="Mesa OpenGL Multi-Thread & Sınırsız FPS Aktif Et:FBTN" "$SCRIPT_PATH --mesa-opengl-boost" \
    --field="RAM Katili (Arka Plan Uygulamalarını Kapat):FBTN" "$SCRIPT_PATH --clear-background" \
    --field="GameMode Altyapısını Başlat (Feral):FBTN" "$SCRIPT_PATH --gamemode-start" \
    --field="Goverlay (Oyun İçi Gelişmiş FPS/Grafik Göstergesi):FBTN" "$SCRIPT_PATH --goverlay-open" \
    --button="Menüyü Kapat:0"

exit 0
