#!/bin/bash
# ==============================================================================
# MELES OS: MERKEZİ ARAÇLAR VE TÜM KURULU UYGULAMALAR (LIVE DYNAMIC ENGINE)
# Standart: Saf Bash + YAD/GTK3 | Canlı Sistem Taraması & Orijinal Simgeler
# ==============================================================================

export GTK_THEME="Adwaita:dark"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 1. CANLI SİSTEM UYGULAMA MOTORU (DİNAMİK .DESKTOP AYIKLAYICI)
# ------------------------------------------------------------------------------
uygulamalari_tara() {
    local DIRS=(
        "/usr/share/applications"
        "/usr/local/share/applications"
        "$HOME/.local/share/applications"
        "/var/lib/flatpak/exports/share/applications"
        "$HOME/.local/share/flatpak/exports/share/applications"
    )

    declare -A GORULENLER

    for dir in "${DIRS[@]}"; do
        [ -d "$dir" ] || continue
        for file in "$dir"/*.desktop; do
            [ -f "$file" ] || continue

            # NoDisplay veya Hidden olanları atla
            if grep -qE '^NoDisplay=(true|TRUE)' "$file" 2>/dev/null || \
               grep -qE '^Hidden=(true|TRUE)' "$file" 2>/dev/null; then
                continue
            fi

            # Yalnızca Application türünü al
            if ! grep -qE '^Type=Application' "$file" 2>/dev/null; then
                continue
            fi

            # İsim Ayıkla (Varsa Türkçe, yoksa varsayılan)
            local ISIM=$(grep -m1 '^Name\[tr\]=' "$file" 2>/dev/null | cut -d'=' -f2-)
            if [ -z "$ISIM" ]; then
                ISIM=$(grep -m1 '^Name=' "$file" 2>/dev/null | cut -d'=' -f2-)
            fi
            [ -z "$ISIM" ] && continue

            # Çiftleri engelle
            if [ -n "${GORULENLER[$ISIM]}" ]; then
                continue
            fi
            GORULENLER[$ISIM]=1

            # İkon Ayıkla
            local IKON=$(grep -m1 '^Icon=' "$file" 2>/dev/null | cut -d'=' -f2-)
            [ -z "$IKON" ] && IKON="application-x-executable"

            # Açıklama / Kategori
            local ACIKLAMA=$(grep -m1 '^Comment\[tr\]=' "$file" 2>/dev/null | cut -d'=' -f2-)
            [ -z "$ACIKLAMA" ] && ACIKLAMA=$(grep -m1 '^Comment=' "$file" 2>/dev/null | cut -d'=' -f2-)
            [ -z "$ACIKLAMA" ] && ACIKLAMA=$(grep -m1 '^GenericName=' "$file" 2>/dev/null | cut -d'=' -f2-)
            [ -z "$ACIKLAMA" ] && ACIKLAMA="Sistem Uygulaması"

            # Komut Ayıkla ve Parametreleri Temizle (%U, %F vb.)
            local KOMUT=$(grep -m1 '^Exec=' "$file" 2>/dev/null | cut -d'=' -f2- | sed -E 's/%[a-zA-Z]//g; s/"//g')
            [ -z "$KOMUT" ] && continue

            # YAD List Formatı: İkon | İsim | Açıklama | Komut
            echo "$IKON"
            echo "$ISIM"
            echo "$ACIKLAMA"
            echo "$KOMUT"
        done
    done
}

# ------------------------------------------------------------------------------
# 2. AYRI TÜM UYGULAMALAR PENCERESİ ÇAĞRICISI
# ------------------------------------------------------------------------------
if [ "$1" == "--tum-uygulamalar" ]; then
    SECILEN=$(uygulamalari_tara | yad --list \
        --title="Meles OS - Kurulu Tüm Uygulamalar" \
        --width=860 --height=580 --center \
        --image-column=1 \
        --column="Logo:IMG" \
        --column="Uygulama Adı:TEXT" \
        --column="Açıklama:TEXT" \
        --column="Komut:HD" \
        --search-column=2 \
        --text="<span font='14' weight='bold' color='#38bdf8'>  Sistemde Kurulu Tüm Uygulamalar</span>\n<span color='#94a3b8'>  Çalıştırmak istediğiniz uygulamanın üzerine çift tıklayın veya seçip Başlat'a basın. (Arama yapmak için doğrudan yazabilirsiniz)</span>" \
        --button="Uygulamayı Başlat:0" \
        --button="Kapat:1")

    if [ $? -eq 0 ] && [ -n "$SECILEN" ]; then
        CALISTIR=$(echo "$SECILEN" | awk -F'|' '{print $4}')
        if [ -n "$CALISTIR" ]; then
            eval "$CALISTIR" &
        fi
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# 3. YÖNETİM VE SİSTEM ARAÇLARI ÇAĞRICILARI
# ------------------------------------------------------------------------------
if [ "$1" == "--act-yedek" ]; then
    timeshift-gtk 2>/dev/null || pkexec timeshift-launcher 2>/dev/null || deja-dup 2>/dev/null || yad --info --text="Timeshift kurulu değil." --timeout=2 &
    exit 0
elif [ "$1" == "--act-liveiso" ]; then
    systemback 2>/dev/null || refractasnapshot-gui 2>/dev/null || isodumper 2>/dev/null || yad --info --text="Canlı ISO Aracı hazırlanıyor..." --timeout=2 &
    exit 0
elif [ "$1" == "--act-disk" ]; then
    gparted 2>/dev/null || pkexec gparted 2>/dev/null || gnome-disks 2>/dev/null &
    exit 0
elif [ "$1" == "--act-temizlik" ]; then
    bleachbit 2>/dev/null || stacer 2>/dev/null || (gnome-terminal -- bash -c "sudo apt clean && sudo apt autoremove -y; read -p 'Bitti...'") &
    exit 0
elif [ "$1" == "--act-onarim" ]; then
    boot-repair 2>/dev/null || (gnome-terminal -- bash -c "sudo dpkg --configure -a && sudo apt install -f -y && sudo update-grub; read -p 'Onarıldı...'") &
    exit 0
elif [ "$1" == "--act-cizelge" ]; then
    gnome-schedule 2>/dev/null || (gnome-terminal -- bash -c "crontab -e") &
    exit 0
elif [ "$1" == "--act-taskman" ]; then
    xfce4-taskmanager 2>/dev/null || gnome-system-monitor 2>/dev/null || htop &
    exit 0
elif [ "$1" == "--act-driver" ]; then
    if [ -x /usr/local/bin/meles_glass_center.py ]; then
        python3 /usr/local/bin/meles_glass_center.py &
    else
        software-properties-gtk --open-tab=4 2>/dev/null || hardinfo 2>/dev/null || (gnome-terminal -- bash -c "inxi -Fz; read -p 'Kapat...'") &
    fi
    exit 0
elif [ "$1" == "--act-ses" ]; then
    pavucontrol 2>/dev/null || gnome-control-center sound 2>/dev/null || alsamixer &
    exit 0
elif [ "$1" == "--act-saat" ]; then
    time-admin 2>/dev/null || gnome-control-center datetime 2>/dev/null || (pkexec timedatectl set-ntp true && yad --info --text="Saat senkronize edildi." --timeout=2) &
    exit 0
elif [ "$1" == "--act-giris" ]; then
    lightdm-gtk-greeter-settings 2>/dev/null || yad --info --text="Giriş ekranı yöneticisi aktif." --timeout=2 &
    exit 0
elif [ "$1" == "--act-kullanicilar" ]; then
    users-admin 2>/dev/null || gnome-control-center user-accounts 2>/dev/null &
    exit 0
elif [ "$1" == "--act-guncelleme" ]; then
    update-manager 2>/dev/null || mintupdate 2>/dev/null || (gnome-terminal -- bash -c "sudo apt update && sudo apt upgrade -y; read -p 'Bitti...'") &
    exit 0
elif [ "$1" == "--act-pkg-update" ]; then
    synaptic 2>/dev/null || gnome-software 2>/dev/null &
    exit 0
elif [ "$1" == "--act-pkg-install" ]; then
    gdebi-gtk 2>/dev/null || (
        DEB=$(yad --file --title="Paket Seç (.deb)" --center --file-filter="Debian Paketleri (*.deb) | *.deb")
        [ -n "$DEB" ] && gnome-terminal -- bash -c "sudo apt install -y '$DEB'; read -p 'Bitti...'"
    ) &
    exit 0
fi

# ------------------------------------------------------------------------------
# 4. ÇOK SEKME VE DİNAMİK LİSTE MOTORU
# ------------------------------------------------------------------------------
KEY=$RANDOM

HEADER_TEXT="<span font='28' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES ARAÇLAR MERKEZİ</b></span>\n<span font='10' color='#94a3b8'>       Sistem yönetim araçları ve kurulu uygulamalar kataloğu:</span>\n"

# SEKME 1: CANLI KURULU TÜM UYGULAMALAR (GERÇEK GTK LOGOLARIYLA)
uygulamalari_tara | yad --plug=$KEY --tabnum=1 --list \
    --image-column=1 \
    --column="Logo:IMG" \
    --column="Uygulama Adı:TEXT" \
    --column="Açıklama:TEXT" \
    --column="Komut:HD" \
    --search-column=2 \
    --text="<span color='#94a3b8'>Bilgisayarınızda kurulu olan tüm programlar (Aramak için yazmaya başlayın):</span>\n" \
    &> /tmp/meles_app_secim.tmp &

# SEKME 2: YEDEKLEME VE DİSK YÖNETİMİ
yad --plug=$KEY --tabnum=2 --form --columns=2 \
    --text="$HEADER_TEXT" \
    --field="  [ 1 ]  Anlık Sistem Yedekleme (Timeshift):FBTN" "bash \"$0\" --act-yedek" \
    --field="  [ 2 ]  Live ISO Oluşturucu:FBTN" "bash \"$0\" --act-liveiso" \
    --field="  [ 14 ] Disk Bölümleme ve Format (GParted):FBTN" "bash \"$0\" --act-disk" \
    --field="  Sistem Görev Yöneticisi (Task Manager):FBTN" "bash \"$0\" --act-taskman" \
    &

# SEKME 3: BAKIM, ONARIM VE DEPOLAR
yad --plug=$KEY --tabnum=3 --form --columns=2 \
    --text="$HEADER_TEXT" \
    --field="  [ 3 ]  Sistem Temizliği (BleachBit):FBTN" "bash \"$0\" --act-temizlik" \
    --field="  [ 5 ]  Sistem ve Başlangıç Onarımı:FBTN" "bash \"$0\" --act-onarim" \
    --field="  [ 6 ]  Zamanlanmış Görev Çizelgesi:FBTN" "bash \"$0\" --act-cizelge" \
    --field="  [ 11 ] Güncelleme Merkezi:FBTN" "bash \"$0\" --act-guncelleme" \
    --field="  [ 12 ] Gelişmiş Paket Depoları (Synaptic):FBTN" "bash \"$0\" --act-pkg-update" \
    --field="  [ 13 ] Paket Yükleyici (GDebi .deb):FBTN" "bash \"$0\" --act-pkg-install" \
    --field="  Meles Hızlı Paket Kurucu:FBTN" "/usr/local/bin/meles-hizli-yukleyici.sh" \
    &

# SEKME 4: DONANIM VE SİSTEM GİRİŞİ
yad --plug=$KEY --tabnum=4 --form --columns=2 \
    --text="$HEADER_TEXT" \
    --field="  [ 8 ]  Sürücü Yöneticisi (Ek Donanımlar):FBTN" "bash \"$0\" --act-driver" \
    --field="  [ 9 ]  Ses Ayarları (Pavucontrol):FBTN" "bash \"$0\" --act-ses" \
    --field="  [ 7 ]  Saat ve Tarih Senkronizasyonu:FBTN" "bash \"$0\" --act-saat" \
    --field="  [ 10 ] Giriş Ekranı Ayarları (LightDM):FBTN" "bash \"$0\" --act-giris" \
    --field="  [ 4 ]  Kullanıcı Hesapları Yönetimi:FBTN" "bash \"$0\" --act-kullanicilar" \
    --field="":LBL "" \
    &

# ------------------------------------------------------------------------------
# 5. ANA PENCERE MOTORU (TAM KOYU MOD)
# ------------------------------------------------------------------------------
yad --notebook --key=$KEY --tab-pos=top \
    --title="Meles OS Araçlar ve Uygulamalar Merkezi" \
    --width=880 --height=580 --center \
    --tab="Tüm Kurulu Uygulamalar" \
    --tab="Yedekleme ve Disk" \
    --tab="Bakım ve Depolar" \
    --tab="Donanım ve Giriş" \
    --button="Seçilen Uygulamayı Başlat:2" \
    --button="Kapat:0"

RET_CODE=$?

# Uygulama Başlat butonuna basıldıysa
if [ $RET_CODE -eq 2 ] && [ -f /tmp/meles_app_secim.tmp ]; then
    SECILEN_APP=$(cat /tmp/meles_app_secim.tmp | awk -F'|' '{print $4}')
    if [ -n "$SECILEN_APP" ]; then
        eval "$SECILEN_APP" &
    fi
fi
rm -f /tmp/meles_app_secim.tmp

exit 0
