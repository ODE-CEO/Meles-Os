#!/bin/bash
# ==============================================================================
# MELES OS: UYGULAMA VE KISAYOL ENJEKTÖRÜ (BÖLÜM 2)
# ==============================================================================

echo ">>> [APP_PART2.SH] 🪟 Windows Köprüsü, Tepsi Turbo ve Hızlı Erişim hazırlanıyor..."

# SUDO TUZAĞINI BOZAN DİNAMİK DİZİN TESPİTİ 🎯
if [ -n "$ASIL_DIZIN" ]; then
    KAYNAK_DIZIN="$ASIL_DIZIN"
elif [ -d "$HOME/meles_os_workspace" ]; then
    KAYNAK_DIZIN="$HOME/meles_os_workspace"
else
    KAYNAK_DIZIN="/home/yagiz/meles_os_workspace"
fi

HEDEF_BIN="config/includes.chroot/usr/local/bin"
HEDEF_SHARE="config/includes.chroot/usr/local/share"
HEDEF_APPS="config/includes.chroot/usr/share/applications"
HEDEF_AUTOSTART="config/includes.chroot/etc/skel/.config/autostart"
HEDEF_XDG_AUTOSTART="config/includes.chroot/etc/xdg/autostart"
HEDEF_NAUTILUS_SCRIPTS="config/includes.chroot/etc/skel/.local/share/nautilus/scripts"

mkdir -p "$HEDEF_APPS" "$HEDEF_BIN" "$HEDEF_SHARE" "$HEDEF_AUTOSTART" "$HEDEF_XDG_AUTOSTART" "$HEDEF_NAUTILUS_SCRIPTS"

# 9. MELES WINDOWS KÖPRÜSÜ (.EXE & .MSI SAĞ TIK VE ÇİFT TIK ÇALIŞTIRICI) 🪟⚡
echo ">>> [APP_PART2.SH] 🪟 Meles Windows Köprüsü entegre ediliyor..."

cat << 'RUNNER_EOF' > "$HEDEF_BIN/meles-exe-runner.sh"
#!/bin/bash
# Meles OS Windows Köprüsü - Sessiz ve Akıllı Çalıştırıcı

DOSYA="$1"

if [ -z "$DOSYA" ]; then
    if command -v zenity &>/dev/null; then
        DOSYA=$(zenity --file-selection --title="Çalıştırmak İstediğiniz .EXE veya .MSI Dosyasını Seçin" --file-filter="Windows Uygulamaları (*.exe *.msi) | *.exe *.msi *.EXE *.MSI")
    fi
fi

[ -z "$DOSYA" ] && exit 0

DOSYA_ADI=$(basename "$DOSYA")

if command -v notify-send &>/dev/null; then
    notify-send "Meles Windows Köprüsü" "<b>$DOSYA_ADI</b> başlatılıyor..." -i wine -t 4000
fi

export WINEPREFIX="$HOME/.meles_wine"
export WINEDEBUG="-all"

if [[ "$DOSYA" == *.msi || "$DOSYA" == *.MSI ]]; then
    exec wine msiexec /i "$DOSYA"
else
    exec wine "$DOSYA"
fi
RUNNER_EOF
chmod +x "$HEDEF_BIN/meles-exe-runner.sh"

cat << 'DSK_EOF' > "$HEDEF_APPS/meles-exe-runner.desktop"
[Desktop Entry]
Name=Meles Windows Köprüsü
GenericName=Windows Uygulama Çalıştırıcı
Comment=Windows uygulamalarını (.exe / .msi) Meles OS üzerinde doğrudan çalıştırın
Exec=/usr/local/bin/meles-exe-runner.sh %f
Icon=wine
Terminal=false
Type=Application
MimeType=application/x-ms-dos-executable;application/x-msdownload;application/x-dosexec;application/x-msi;
Categories=Utility;Emulator;System;
NoDisplay=false
StartupNotify=true
DSK_EOF
chmod +x "$HEDEF_APPS/meles-exe-runner.desktop"

mkdir -p config/includes.chroot/etc/skel/.config
mkdir -p config/includes.chroot/usr/share/applications

MIME_CONTENT="[Default Applications]
application/x-ms-dos-executable=meles-exe-runner.desktop
application/x-msdownload=meles-exe-runner.desktop
application/x-dosexec=meles-exe-runner.desktop
application/x-msi=meles-exe-runner.desktop

[Added Associations]
application/x-ms-dos-executable=meles-exe-runner.desktop;
application/x-msdownload=meles-exe-runner.desktop;
application/x-dosexec=meles-exe-runner.desktop;
application/x-msi=meles-exe-runner.desktop;"

echo "$MIME_CONTENT" > config/includes.chroot/etc/skel/.config/mimeapps.list
echo "$MIME_CONTENT" > config/includes.chroot/usr/share/applications/mimeapps.list

# 10. TEK TIK TURBO: SAĞ ALT SİSTEM TEPSİSİ (APPINDICATOR / TRAY) ⚡🚀
echo ">>> [APP_PART2.SH] 🚀 Meles Turbo sistem tepsisine (sağ alta) bağlanıyor..."

cat << 'TURBO_EOF' > "$HEDEF_BIN/meles-turbo.sh"
#!/bin/bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    exec pkexec /usr/local/bin/meles-turbo.sh
fi

RESULT=""
if command -v powerprofilesctl >/dev/null 2>&1 &&
    powerprofilesctl set performance >/dev/null 2>&1; then
    RESULT="Güç profili performans moduna alındı."
else
    UPDATED=0
    for governor in /sys/devices/system/cpu/cpufreq/policy*/scaling_governor \
        /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        [[ -e "$governor" ]] || continue
        [[ -w "$governor" ]] || continue
        available="${governor%/*}/scaling_available_governors"
        [[ -r "$available" ]] || continue
        if grep -qw performance "$available"; then
            printf 'performance\n' > "$governor"
            UPDATED=$((UPDATED + 1))
        fi
    done
    if [[ "$UPDATED" -eq 0 ]]; then
        echo "Bu işlemcide performance güç profili/governor kullanılamıyor." >&2
        exit 1
    fi
    RESULT="$UPDATED CPU governor performans moduna alındı."
fi

printf '%s\n' "$RESULT"
TURBO_EOF
chmod +x "$HEDEF_BIN/meles-turbo.sh"

cat << 'TURBO_LAUNCHER_EOF' > "$HEDEF_BIN/meles-turbo-launcher.sh"
#!/bin/bash
OUTPUT=$(pkexec /usr/local/bin/meles-turbo.sh 2>&1)
STATUS=$?
if [[ "$STATUS" -eq 0 ]]; then
    yad --info --title="Meles Turbo" --center --text="$OUTPUT"
else
    yad --error --title="Meles Turbo" --center --text="Performans profili uygulanamadı.\n\n$OUTPUT"
fi
exit "$STATUS"
TURBO_LAUNCHER_EOF
chmod +x "$HEDEF_BIN/meles-turbo-launcher.sh"

# Legacy tray launcher is kept available but disabled by default to avoid a
# permanent YAD process in every desktop session.
cat << 'TRAY_EOF' > "$HEDEF_BIN/meles-turbo-tray.sh"
#!/bin/bash
while true; do
    yad --notification \
        --image="weather-storm" \
        --text="Meles Turbo Boost (Tıkla ve Sistemi Temizle)" \
        --command="meles-turbo-launcher.sh" \
        --menu="🚀 Turbo Performans Modunu Çalıştır!meles-turbo-launcher.sh|ℹ️ Meles OS Karşılama!meles-karsilama" 2>/dev/null
    sleep 3
done
TRAY_EOF
chmod +x "$HEDEF_BIN/meles-turbo-tray.sh"

# Açılışta Sağ Altta Otomatik Başlat
cat << AUTO_EOF > "$HEDEF_XDG_AUTOSTART/meles-turbo-tray.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/meles-turbo-tray.sh
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=false
Name=Meles Turbo Tray
Comment=Meles OS Sistem Tepsisi Performans Aracı
Icon=weather-storm
AUTO_EOF
cp "$HEDEF_XDG_AUTOSTART/meles-turbo-tray.desktop" "$HEDEF_AUTOSTART/meles-turbo-tray.desktop" 2>/dev/null || true

cat << 'TURBO_DESKTOP_EOF' > "$HEDEF_APPS/Meles_Turbo.desktop"
[Desktop Entry]
Type=Application
Name=Meles Turbo
Comment=İşlemci performans profilini etkinleştir
Exec=/usr/local/bin/meles-turbo-launcher.sh
Icon=weather-storm
Terminal=false
Categories=System;
StartupNotify=true
TURBO_DESKTOP_EOF

# 11. NAUTILUS SAĞ TIK: MODERN VE SAF KOYU HIZLI ERİŞİM SİSTEMİ 📂💎
echo ">>> [APP_PART2.SH] 📂 Modern Nautilus Hızlı Erişim Araçları işleniyor..."

cat << 'ERISIM_EOF' > "$HEDEF_BIN/hizli_erisim.sh"
#!/bin/bash
# ==============================================================================
# MELES OS: TITANIUM SAĞ TIK HIZLI ERİŞİM SİSTEMİ (MODERN ADWAITA-DARK)
# ==============================================================================
export GTK_THEME="Adwaita:dark"

SECILI="$1"
[ -z "$SECILI" ] && SECILI="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS%%$'\n'*}"

HEADER="<span font='13' weight='heavy' color='#38bdf8'>⚡ MELES HIZLI ERİŞİM</span>"

# 1. DURUM: Klasör veya Boş Alan
if [ -z "$SECILI" ] || [ -d "$SECILI" ]; then
    HEDEF_DIR="$SECILI"
    [ -z "$HEDEF_DIR" ] && HEDEF_DIR="$PWD"
    DIR_NAME=$(basename "$HEDEF_DIR")
    [ "$DIR_NAME" == "" ] && DIR_NAME="Kök Dizin"

    ISLEM=$(yad --list --title="Meles Klasör Araçları" --width=480 --height=260 --center \
        --window-icon="folder" \
        --text="$HEADER\n<span font='10' color='#cbd5e1'>Konum: <b>$DIR_NAME</b></span>\n" \
        --column="":IMG --column="Kod":HD --column="İşlem":TEXT --column="Açıklama":TEXT \
        "utilities-terminal" "ROOT_TERM" "Root Terminal Aç" "Klasörde tam yetkili terminal başlatır" \
        "accessories-text-editor" "GEDIT_ROOT" "Root Metin Editörü" "Dosyaları yönetici olarak düzenleyin" \
        "drive-harddisk" "BOYUT" "Boyut Analizi Yap" "Klasörün diskteki yerini hesaplar" \
        --button="Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ] && [ -n "$ISLEM" ]; then
        KOD=$(echo "$ISLEM" | awk -F'|' '{print $2}')
        case "$KOD" in
            "ROOT_TERM")
                pkexec gnome-terminal --working-directory="$HEDEF_DIR" &
                ;;
            "GEDIT_ROOT")
                pkexec gedit &
                ;;
            "BOYUT")
                TOPLAM=$(du -sh "$HEDEF_DIR" 2>/dev/null | awk '{print $1}')
                notify-send "Meles Boyut Analizi" "<b>$DIR_NAME</b> klasör boyutu: <b>$TOPLAM</b>" -i drive-harddisk -t 4000
                ;;
        esac
    fi
    exit 0
fi

# Dosya Detaylarını Al
DOSYA_ADI=$(basename "$SECILI")
DIR_NAME=$(dirname "$SECILI")
BASE_NAME="${DOSYA_ADI%.*}"
UZANTI="${DOSYA_ADI##*.}"
UZANTI_KUCUK=$(echo "$UZANTI" | tr '[:upper:]' '[:lower:]')

# 2. DURUM: Görseller
if [[ "$UZANTI_KUCUK" =~ ^(jpg|jpeg|png|webp|bmp)$ ]]; then
    ISLEM=$(yad --list --title="Meles Görsel Araçları" --width=520 --height=290 --center \
        --window-icon="image-x-generic" \
        --text="$HEADER\n<span font='10' color='#cbd5e1'>Görsel: <b>$DOSYA_ADI</b></span>\n" \
        --column="":IMG --column="Kod":HD --column="İşlem":TEXT --column="Açıklama":TEXT \
        "image-x-generic" "RESIZE" "Web İçin Küçült" "%50 boyutlandırır ve sıkıştırır" \
        "x-office-document" "TO_PDF" "PDF'e Dönüştür" "Görselden tek tıkla PDF belgesi üretir" \
        "preferences-desktop-wallpaper" "WALLPAPER" "Masaüstü Arka Planı Yap" "Görseli anında duvar kağıdı ayarlar" \
        --button="Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ] && [ -n "$ISLEM" ]; then
        KOD=$(echo "$ISLEM" | awk -F'|' '{print $2}')
        case "$KOD" in
            "RESIZE")
                CIKTI="$DIR_NAME/${BASE_NAME}_web.${UZANTI_KUCUK}"
                convert "$SECILI" -resize 50% -quality 85 "$CIKTI"
                notify-send "Meles Görsel" "Optimize edildi:\n<b>$CIKTI</b>" -i image-x-generic -t 4000
                ;;
            "TO_PDF")
                CIKTI="$DIR_NAME/${BASE_NAME}.pdf"
                convert "$SECILI" "$CIKTI"
                notify-send "Meles PDF" "PDF başarıyla üretildi:\n<b>$CIKTI</b>" -i x-office-document -t 4000
                ;;
            "WALLPAPER")
                gsettings set org.gnome.desktop.background picture-uri "file://$SECILI"
                gsettings set org.gnome.desktop.background picture-uri-dark "file://$SECILI"
                notify-send "Meles Görünüm" "Masaüstü duvar kağıdı güncellendi!" -i preferences-desktop-wallpaper -t 3000
                ;;
        esac
    fi
    exit 0
fi

# 3. DURUM: PDF Belgeleri
if [ "$UZANTI_KUCUK" == "pdf" ]; then
    ISLEM=$(yad --list --title="Meles PDF Motoru" --width=480 --height=230 --center \
        --window-icon="x-office-document" \
        --text="$HEADER\n<span font='10' color='#cbd5e1'>Belge: <b>$DOSYA_ADI</b></span>\n" \
        --column="":IMG --column="Kod":HD --column="İşlem":TEXT --column="Açıklama":TEXT \
        "document-save" "COMPRESS" "PDF Boyutunu Sıkıştır" "E-kitap kalitesinde sıkıştırıp yer kazandırır" \
        --button="Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ] && [ -n "$ISLEM" ]; then
        KOD=$(echo "$ISLEM" | awk -F'|' '{print $2}')
        CIKTI="$DIR_NAME/${BASE_NAME}_sikistirilmis.pdf"
        notify-send "Meles PDF" "PDF sıkıştırılıyor, lütfen bekleyin..." -i x-office-document -t 2500
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$CIKTI" "$SECILI"
        notify-send "Meles PDF" "Sıkıştırılmış belge hazır:\n<b>$CIKTI</b>" -i x-office-document -t 4000
    fi
    exit 0
fi

# 4. DURUM: ISO Kalıpları
if [ "$UZANTI_KUCUK" == "iso" ]; then
    ISLEM=$(yad --list --title="Meles ISO Sanal Sürücü" --width=500 --height=250 --center \
        --window-icon="media-optical" \
        --text="$HEADER\n<span font='10' color='#cbd5e1'>Disk Kalıbı: <b>$DOSYA_ADI</b></span>\n" \
        --column="":IMG --column="Kod":HD --column="İşlem":TEXT --column="Açıklama":TEXT \
        "media-optical" "MOUNT" "Sanal Sürücüye Bağla" "Masaüstünde ISO sürücüsü oluşturur" \
        "media-eject" "UNMOUNT" "Bağlantıyı Güvenle Kes" "Sanal sürücüyü sistemden ayırır" \
        --button="Uygula:0" --button="İptal:1")

    if [ $? -eq 0 ] && [ -n "$ISLEM" ]; then
        KOD=$(echo "$ISLEM" | awk -F'|' '{print $2}')
        BAGLANTI_NOKTASI="$HOME/Masaüstü/ISO_Surucu"
        case "$KOD" in
            "MOUNT")
                mkdir -p "$BAGLANTI_NOKTASI"
                pkexec mount -o loop "$SECILI" "$BAGLANTI_NOKTASI"
                notify-send "Meles ISO" "Sanal sürücü bağlandı: Masaüstü/ISO_Surucu" -i media-optical -t 4000
                ;;
            "UNMOUNT")
                pkexec umount "$BAGLANTI_NOKTASI" 2>/dev/null || true
                rmdir "$BAGLANTI_NOKTASI" 2>/dev/null || true
                notify-send "Meles ISO" "Sanal sürücü bağlantısı kesildi." -i media-optical -t 3000
                ;;
        esac
    fi
    exit 0
fi

# 5. DİĞER DOSYALAR
ISLEM=$(yad --list --title="Meles Dosya Güvenliği" --width=500 --height=250 --center \
    --window-icon="security-high" \
    --text="$HEADER\n<span font='10' color='#cbd5e1'>Dosya: <b>$DOSYA_ADI</b></span>\n" \
    --column="":IMG --column="Kod":HD --column="İşlem":TEXT --column="Açıklama":TEXT \
    "security-high" "HASH" "Doğrulama Özeti (Hash)" "SHA256 ve MD5 parmak izlerini hesaplar" \
    "accessories-text-editor" "ROOT_EDIT" "Root ile Düzenle" "Sistem dosyasını yetkili editörle açar" \
    --button="Uygula:0" --button="İptal:1")

if [ $? -eq 0 ] && [ -n "$ISLEM" ]; then
    KOD=$(echo "$ISLEM" | awk -F'|' '{print $2}')
    case "$KOD" in
        "HASH")
            SHA=$(sha256sum "$SECILI" | awk '{print $1}')
            MD5=$(md5sum "$SECILI" | awk '{print $1}')
            yad --text-info --title="Dosya Doğrulama Raporu" --width=620 --height=220 --center \
                --window-icon="security-high" \
                --text="<span font='11' weight='bold' color='#38bdf8'>$DOSYA_ADI</span>\n\n<b>SHA256:</b>\n$SHA\n\n<b>MD5:</b>\n$MD5" \
                --button="Kapat:0"
            ;;
        "ROOT_EDIT")
            pkexec gedit "$SECILI" &
            ;;
    esac
fi
exit 0
ERISIM_EOF

chmod +x "$HEDEF_BIN/hizli_erisim.sh"

# Nautilus Sağ Tık Menüsüne doğrudan komutlar olarak yerleştirme.
# Tek bir seçim penceresi yerine Nautilus'un kendi sağ tık menüsü kullanılır.
cat << 'DIRECT_EOF' > "$HEDEF_BIN/meles-hizli-islem.sh"
#!/bin/bash
set -u

SECILI="${1:-}"
[ -z "$SECILI" ] && SECILI="${NAUTILUS_SCRIPT_SELECTED_FILE_PATHS:-}"
[ -n "$SECILI" ] && SECILI="${SECILI%%$'\n'*}"
ISLEM="${2:-}"

if [ -z "$SECILI" ]; then
    notify-send "Meles Hızlı Erişim" "Önce bir dosya veya klasör seçin." -i dialog-warning
    exit 1
fi

case "$ISLEM" in
    terminal)
        [ -d "$SECILI" ] || SECILI="$(dirname "$SECILI")"
        exec gnome-terminal --working-directory="$SECILI"
        ;;
    boyut)
        [ -d "$SECILI" ] || SECILI="$(dirname "$SECILI")"
        TOPLAM=$(du -sh -- "$SECILI" 2>/dev/null | awk '{print $1}')
        notify-send "Meles Boyut Analizi" "$(basename "$SECILI"): ${TOPLAM:-hesaplanamadı}" -i drive-harddisk
        ;;
    pdf)
        DIR_NAME=$(dirname "$SECILI")
        BASE_NAME="${SECILI##*/}"
        BASE_NAME="${BASE_NAME%.*}"
        CIKTI="$DIR_NAME/${BASE_NAME}.pdf"
        convert -- "$SECILI" "$CIKTI" &&
            notify-send "Meles PDF" "PDF hazır: $CIKTI" -i x-office-document
        ;;
    resize)
        DIR_NAME=$(dirname "$SECILI")
        DOSYA_ADI=$(basename "$SECILI")
        BASE_NAME="${DOSYA_ADI%.*}"
        UZANTI="${DOSYA_ADI##*.}"
        CIKTI="$DIR_NAME/${BASE_NAME}_web.${UZANTI,,}"
        convert -- "$SECILI" -resize 50% -quality 85 "$CIKTI" &&
            notify-send "Meles Görsel" "Optimize edildi: $CIKTI" -i image-x-generic
        ;;
    wallpaper)
        gsettings set org.gnome.desktop.background picture-uri "file://$SECILI"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$SECILI"
        notify-send "Meles Görünüm" "Duvar kağıdı güncellendi." -i preferences-desktop-wallpaper
        ;;
    compress)
        DIR_NAME=$(dirname "$SECILI")
        BASE_NAME="${SECILI##*/}"
        BASE_NAME="${BASE_NAME%.*}"
        CIKTI="$DIR_NAME/${BASE_NAME}_sikistirilmis.pdf"
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
            -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$CIKTI" "$SECILI" &&
            notify-send "Meles PDF" "Sıkıştırılmış PDF hazır: $CIKTI" -i x-office-document
        ;;
    mount)
        BAGLANTI_NOKTASI="$HOME/Masaüstü/ISO_Surucu"
        mkdir -p "$BAGLANTI_NOKTASI"
        pkexec mount -o loop "$SECILI" "$BAGLANTI_NOKTASI" &&
            notify-send "Meles ISO" "ISO bağlandı: $BAGLANTI_NOKTASI" -i media-optical
        ;;
    unmount)
        BAGLANTI_NOKTASI="$HOME/Masaüstü/ISO_Surucu"
        pkexec umount "$BAGLANTI_NOKTASI" &&
            rmdir "$BAGLANTI_NOKTASI" 2>/dev/null || true
        ;;
    hash)
        SHA=$(sha256sum -- "$SECILI" | awk '{print $1}')
        notify-send "Meles Dosya Doğrulama" "$(basename "$SECILI") SHA256: $SHA" -i security-high
        ;;
    *)
        notify-send "Meles Hızlı Erişim" "Geçersiz işlem." -i dialog-error
        exit 2
        ;;
esac
DIRECT_EOF
chmod +x "$HEDEF_BIN/meles-hizli-islem.sh"

for tanim in \
    "Meles Terminalde Aç|Meles_Terminalde_Ac|terminal" \
    "Meles Boyut Analizi|Meles_Boyut_Analizi|boyut" \
    "Meles PDF Oluştur|Meles_PDF_Olustur|pdf" \
    "Meles Görseli Küçült|Meles_Gorseli_Kucult|resize" \
    "Meles Duvar Kağıdı Yap|Meles_Duvar_Kagidi|wallpaper" \
    "Meles PDF Sıkıştır|Meles_PDF_Sikistir|compress" \
    "Meles ISO Bağla|Meles_ISO_Bagla|mount" \
    "Meles ISO Ayır|Meles_ISO_Ayir|unmount" \
    "Meles SHA256 Hesapla|Meles_SHA256|hash"; do
    IFS='|' read -r AD DOSYA ISLEM <<< "$tanim"
    cat > "$HEDEF_NAUTILUS_SCRIPTS/$AD" << EOF
#!/bin/bash
exec /usr/local/bin/meles-hizli-islem.sh "\${1:-}" "$ISLEM"
EOF
    chmod +x "$HEDEF_NAUTILUS_SCRIPTS/$AD"
done
rm -f "$HEDEF_NAUTILUS_SCRIPTS/Meles Hızlı Erişim"

# 12. YETKİLENDİRME & BAŞLAT MENÜSÜ İNDEKS ZIRHI 🛡️💎
chmod -R 755 "$HEDEF_SHARE/meles_gorunum" 2>/dev/null || true
chmod -R 755 "$HEDEF_SHARE/meles_karsilama" 2>/dev/null || true
chmod +x "$HEDEF_SHARE/meles_karsilama"/*.sh 2>/dev/null || true
chmod +x "$HEDEF_APPS"/*.desktop 2>/dev/null || true
chmod +x "$HEDEF_BIN"/* 2>/dev/null || true

echo ">>> [APP_PART2.SH] 🎉 Meles Araçları, Windows Köprüsü, Tepsi Turbo ve Hızlı Erişim başarıyla entegre edildi! Masaüstü tertemiz."
