#!/bin/bash
# ==============================================================================
# MELES OS: İNCE AYAR VE ÖZELLEŞTİRME MERKEZİ (MELES TWEAK - GNOME EDITION)
# Standart: Saf Bash + YAD/GTK3 | GNOME Shell + Dash-to-Panel + ArcMenu
# ==============================================================================

export GTK_THEME="Adwaita:dark"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config/meles_panel_backups"
mkdir -p "$BACKUP_DIR"

# ------------------------------------------------------------------------------
# 0. SİSTEM MEVCUT DURUMUNU TESPİT ETME (SİSTEM OKUYUCU)
# ------------------------------------------------------------------------------
PRIMARY_DISPLAY=$(xrandr --query 2>/dev/null | grep ' connected' | head -n 1 | awk '{print $1}')
[ -z "$PRIMARY_DISPLAY" ] && PRIMARY_DISPLAY="eDP-1"
RESOLUTIONS=$(xrandr --query 2>/dev/null | awk '/ connected/{flag=1; next} /^[a-zA-Z]/{flag=0} flag {print $1}' | tr '\n' '!')
[ -z "$RESOLUTIONS" ] && RESOLUTIONS="1920x1080!1366x768!1280x720"

GTK_THEMES=$(find /usr/share/themes "$HOME/.themes" -maxdepth 1 -type d 2>/dev/null | awk -F'/' '{print $NF}' | grep -v '^themes$' | sort -u | tr '\n' '!')
ICON_THEMES=$(find /usr/share/icons "$HOME/.icons" -maxdepth 1 -type d 2>/dev/null | awk -F'/' '{print $NF}' | grep -v '^icons$' | sort -u | tr '\n' '!')
CURRENT_HOSTNAME=$(hostname)
AYAR_HATALARI=()

gsettings() {
    local output
    if output=$(command gsettings "$@" 2>&1); then
        return 0
    else
        AYAR_HATALARI+=("$*: ${output:-komut başarısız oldu}")
        return 1
    fi
}

ayar_sonuc() {
    local mesaj="$1"
    if [ "${#AYAR_HATALARI[@]}" -gt 0 ]; then
        yad --warning --title="Meles İnce Ayar" --center --width=680 \
            --text="$mesaj\n\nUygulanamayan ayarlar:\n$(printf '%s\n' "${AYAR_HATALARI[@]}")"
    else
        yad --info --title="Meles İnce Ayar" --text="$mesaj" --center --timeout=2 --no-buttons
    fi
}

# ------------------------------------------------------------------------------
# 1. GERÇEK SİSTEM AKSİYONLARI VE UYGULAYICILAR (CALLBACKS - GNOME UYUMLU)
# ------------------------------------------------------------------------------

# --- SEKME 1: PANEL UYGULA ---
if [ "$1" == "--apply-panel" ]; then
    KONUM="$2"
    STIL="$3"
    
    if ! gsettings list-schemas | grep -Fxq "org.gnome.shell.extensions.dash-to-panel"; then
        AYAR_HATALARI+=("Dash-to-Panel uzantısı yüklenmedi")
        ayar_sonuc "Görev çubuğu ayarlanamadı."
        exit 0
    fi
    gnome-extensions enable dash-to-panel@jderose9.github.com 2>/dev/null || true

    case "$KONUM" in
        "Alt (Horizontal)")
            gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'BOTTOM'
            ;;
        "Üst (Horizontal)")
            gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'TOP'
            ;;
        "Sol (Vertical)")
            gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'LEFT'
            ;;
        "Sağ (Vertical)")
            gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'RIGHT'
            ;;
    esac

    if [ "$STIL" == "Modern Docklike İkon Modu" ]; then
        gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 36
        gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin 4
        gsettings set org.gnome.shell.extensions.dash-to-panel appicon-padding 6
    else
        gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 30
        gsettings set org.gnome.shell.extensions.dash-to-panel appicon-margin 2
        gsettings set org.gnome.shell.extensions.dash-to-panel appicon-padding 4
    fi

    ayar_sonuc "Panel ayarları uygulandı."
    exit 0

# --- PANEL YEDEKLE / GERİ YÜKLE ---
elif [ "$1" == "--backup-panel" ]; then
    BACKUP_FILE="$BACKUP_DIR/dtp_backup_$(date +%d.%m.%Y_%H.%M.%S).dconf"
    dconf dump /org/gnome/shell/extensions/dash-to-panel/ > "$BACKUP_FILE" 2>/dev/null || true
    yad --info --text="Panel yedeği alındı:\n$BACKUP_FILE" --center --timeout=3
    exit 0

elif [ "$1" == "--reset-panel" ]; then
    dconf reset -f /org/gnome/shell/extensions/dash-to-panel/ 2>/dev/null || AYAR_HATALARI+=("Panel ayarları sıfırlanamadı")
    gsettings set org.gnome.shell.extensions.dash-to-panel panel-position 'BOTTOM' 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 30 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-bg true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#000000' 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-opacity true 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-panel trans-panel-opacity 1.0 2>/dev/null || true
    gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-file '/usr/share/icons/meleslogo.png' 2>/dev/null || true
    ayar_sonuc "Varsayılan Meles Titanium paneline dönüldü."
    exit 0

# --- SEKME 2: TEMA UYGULA ---
elif [ "$1" == "--apply-theme" ]; then
    GTK_SEC="$2"
    ICON_SEC="$3"
    PRESET="$4"
    DARK_CHK="$5"

    if [ "$PRESET" == "Titanium Dark (Varsayılan)" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#000000' 2>/dev/null || true
    elif [ "$PRESET" == "Obsidian Pure Black" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#000000' 2>/dev/null || true
    elif [ "$PRESET" == "Clean Light" ]; then
        gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus' 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#e2e8f0' 2>/dev/null || true
    else
        [ -n "$GTK_SEC" ] && gsettings set org.gnome.desktop.interface gtk-theme "$GTK_SEC" 2>/dev/null || true
        [ -n "$ICON_SEC" ] && gsettings set org.gnome.desktop.interface icon-theme "$ICON_SEC" 2>/dev/null || true
        if [ "$DARK_CHK" == "TRUE" ]; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        else
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
        fi
    fi

    ayar_sonuc "Görünüm teması uygulandı."
    exit 0

# --- SEKME 3: KOMPOZİTÖR & ANİMASYONLAR ---
elif [ "$1" == "--apply-compositor" ]; then
    ANIM="$2"
    TILING="$3"
    CENTER="$4"

    if [ "$ANIM" == "TRUE" ]; then
        gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
    else
        gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
    fi
    if [ "$TILING" == "TRUE" ]; then
        gsettings set org.gnome.mutter edge-tiling true 2>/dev/null || true
    else
        gsettings set org.gnome.mutter edge-tiling false 2>/dev/null || true
    fi
    if [ "$CENTER" == "TRUE" ]; then
        gsettings set org.gnome.mutter center-new-windows true 2>/dev/null || true
    else
        gsettings set org.gnome.mutter center-new-windows false 2>/dev/null || true
    fi

    ayar_sonuc "Görsel efektler ve pencere davranışı ayarlandı."
    exit 0

# --- SEKME 4: EKRAN & GÖRÜNTÜ UYGULA ---
elif [ "$1" == "--apply-display" ]; then
    EKRAN="$2"
    COZ="$3"
    PARLAKLIK="$4"
    
    if [ -n "$COZ" ] && [ -n "$EKRAN" ]; then
        xrandr --output "$EKRAN" --mode "$COZ" 2>/dev/null || AYAR_HATALARI+=("$EKRAN ekranında $COZ çözünürlüğü uygulanamadı")
    fi
    if [ -n "$PARLAKLIK" ] && [ -n "$EKRAN" ]; then
        VAL=$(awk "BEGIN {print $PARLAKLIK/100}")
        xrandr --output "$EKRAN" --brightness "$VAL" 2>/dev/null || AYAR_HATALARI+=("$EKRAN ekran parlaklığı ayarlanamadı")
    fi
    ayar_sonuc "Görüntü ayarları uygulandı."
    exit 0

# --- SEKME 5: MASAÜSTÜ & DOSYA ---
elif [ "$1" == "--apply-desktop" ]; then
    HOME_ICON="$2"
    TRASH_ICON="$3"
    ICON_BOYUT="$4"

    if [ "$HOME_ICON" == "TRUE" ]; then
        gsettings set org.gnome.shell.extensions.ding show-home true 2>/dev/null || true
    else
        gsettings set org.gnome.shell.extensions.ding show-home false 2>/dev/null || true
    fi
    if [ "$TRASH_ICON" == "TRUE" ]; then
        gsettings set org.gnome.shell.extensions.ding show-trash true 2>/dev/null || true
    else
        gsettings set org.gnome.shell.extensions.ding show-trash false 2>/dev/null || true
    fi

    case "$ICON_BOYUT" in
        "Küçük (Önerilen)")
            gsettings set org.gnome.shell.extensions.ding icon-size 'small' 2>/dev/null || true
            ;;
        "Standart")
            gsettings set org.gnome.shell.extensions.ding icon-size 'standard' 2>/dev/null || true
            ;;
        "Büyük")
            gsettings set org.gnome.shell.extensions.ding icon-size 'large' 2>/dev/null || true
            ;;
    esac

    ayar_sonuc "Masaüstü simge tercihleri güncellendi."
    exit 0

# --- SEKME 6: SÜPER TUŞU KISAYOLU ---
elif [ "$1" == "--apply-superkey" ]; then
    HEDEF="$2"
    if [ "$HEDEF" == "arcmenu" ]; then
        gsettings set org.gnome.mutter overlay-key '' 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.arcmenu hotkey-open-menu true 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.arcmenu menu-hotkey 'Super_L' 2>/dev/null || true
        ayar_sonuc "Süper (Win) tuşu ArcMenu'ye bağlandı."
    elif [ "$HEDEF" == "gnome" ]; then
        gsettings set org.gnome.mutter overlay-key 'Super_L' 2>/dev/null || true
        gsettings set org.gnome.shell.extensions.arcmenu hotkey-open-menu false 2>/dev/null || true
        ayar_sonuc "Süper (Win) tuşu GNOME Genel Bakış'a döndürüldü."
    fi
    exit 0

# --- SEKME 7: SİSTEM & BLUETOOTH & HOSTNAME ---
elif [ "$1" == "--apply-misc" ]; then
    BT_BOOT="$2"
    YENI_NAME="$3"
    
    if [ -n "$YENI_NAME" ] && [ "$YENI_NAME" != "$CURRENT_HOSTNAME" ]; then
        pkexec hostnamectl set-hostname "$YENI_NAME" 2>/dev/null || AYAR_HATALARI+=("Bilgisayar adı yönetici yetkisiyle değiştirilemedi")
    fi
    if [ "$BT_BOOT" == "TRUE" ]; then
        pkexec systemctl enable --now bluetooth 2>/dev/null || AYAR_HATALARI+=("Bluetooth başlatılamadı")
    else
        pkexec systemctl disable --now bluetooth 2>/dev/null || AYAR_HATALARI+=("Bluetooth kapatılamadı")
    fi
    ayar_sonuc "Sistem ince ayarları uygulandı."
    exit 0
fi

# ------------------------------------------------------------------------------
# 2. YAD 7 SEKME MOTORU (NOTEBOOK PLUGS)
# ------------------------------------------------------------------------------
KEY=$RANDOM

HEADER_TEXT="<span font='24' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='13' weight='bold' color='#f1f5f9'><b>             MELES İNCE AYAR VE ÖZELLEŞTİRME</b></span>\n<span font='9' color='#94a3b8'>       Sistem, panel, ekran ve masaüstü ince yapılandırması:</span>\n"

# SEKME 1: PANEL & GÖREV ÇUBUĞU
yad --plug=$KEY --tabnum=1 --form \
    --text="$HEADER_TEXT" \
    --field="Panel Yerleşimi:CB" "Alt (Horizontal)!Üst (Horizontal)!Sol (Vertical)!Sağ (Vertical)" \
    --field="Görev Listesi Stili:CB" "Standart Görev Listesi!Modern Docklike İkon Modu" \
    --field="Panel Yapılandırmasını Yedekle:FBTN" "bash \"$0\" --backup-panel" \
    --field="Varsayılan Panele Geri Dön:FBTN" "bash \"$0\" --reset-panel" \
    &> /tmp/meles_tweak_tab1.tmp &

# SEKME 2: TEMALAR VE GÖRÜNÜM
yad --plug=$KEY --tabnum=2 --form \
    --text="$HEADER_TEXT" \
    --field="Uygulama Teması (GTK):CB" "$GTK_THEMES" \
    --field="Simge Paketi (Icons):CB" "$ICON_THEMES" \
    --field="Ön Tanımlı Meles Modu:CB" "Titanium Dark (Varsayılan)!Obsidian Pure Black!Clean Light" \
    --field="Karanlık Modu (Dark Theme):CHK" "TRUE" \
    --field="Karanlık Meles Temasını Uygula:FBTN" "bash \"$0\" --apply-theme Adwaita-dark Papirus-Dark \"Titanium Dark (Varsayılan)\" TRUE" \
    --field="Açık Meles Temasını Uygula:FBTN" "bash \"$0\" --apply-theme Adwaita Papirus \"Clean Light\" FALSE" \
    &> /tmp/meles_tweak_tab2.tmp &

# SEKME 3: KOMPOZİTÖR VE EFEKTLER
yad --plug=$KEY --tabnum=3 --form \
    --text="$HEADER_TEXT" \
    --field="Pencere Açılış/Kapanış Animasyonları:CHK" "TRUE" \
    --field="Pencereleri Kenara Yaslama (Edge Tiling):CHK" "TRUE" \
    --field="Yeni Pencereleri Ortala:CHK" "TRUE" \
    &> /tmp/meles_tweak_tab3.tmp &

# SEKME 4: GÖRÜNTÜ VE EKRAN
yad --plug=$KEY --tabnum=4 --form \
    --text="$HEADER_TEXT" \
    --field="Etkin Ekran Çıkışı:CB" "$PRIMARY_DISPLAY" \
    --field="Çözünürlük:CB" "$RESOLUTIONS" \
    --field="Yazılımsal Ekran Parlaklığı (%):NUM" "100!10..100!5" \
    &> /tmp/meles_tweak_tab4.tmp &

# SEKME 5: MASAÜSTÜ VE DOSYA DAVRANIŞLARI
yad --plug=$KEY --tabnum=5 --form \
    --text="$HEADER_TEXT" \
    --field="Masaüstünde Ev Klasörünü Göster:CHK" "TRUE" \
    --field="Masaüstünde Çöp Kutusunu Göster:CHK" "TRUE" \
    --field="Masaüstü Simge Boyutu:CB" "Küçük (Önerilen)!Standart!Büyük" \
    &> /tmp/meles_tweak_tab5.tmp &

# SEKME 6: SÜPER (META) TUŞU
yad --plug=$KEY --tabnum=6 --form \
    --text="$HEADER_TEXT" \
    --field="Süper tuşu davranışı:CB" "ArcMenu (Meles)!GNOME Genel Bakış" \
    --field="Meles Başlat Menüsüne Bağla (ArcMenu):FBTN" "bash \"$0\" --apply-superkey \"arcmenu\"" \
    --field="GNOME Genel Bakış Moduna Bağla:FBTN" "bash \"$0\" --apply-superkey \"gnome\"" \
    &> /tmp/meles_tweak_tab6.tmp &

# SEKME 7: ÇEŞİTLİ SİSTEM AYARLARI (MISCELLANEOUS)
yad --plug=$KEY --tabnum=7 --form \
    --text="$HEADER_TEXT" \
    --field="Açılışta Bluetooth Adaptörünü Otomatik Başlat:CHK" "TRUE" \
    --field="Bilgisayar Adı (Hostname):":TEXT "$CURRENT_HOSTNAME" \
    &> /tmp/meles_tweak_tab7.tmp &

# ------------------------------------------------------------------------------
# 3. ANA PENCERE VE UYGULA DÖNGÜSÜ
# ------------------------------------------------------------------------------
yad --notebook --key=$KEY --tab-pos=top \
    --title="Meles OS İnce Ayar ve Özelleştirme Merkezi" \
    --width=820 --height=560 --center \
    --tab="Panel" \
    --tab="Tema" \
    --tab="Kompozitör" \
    --tab="Görüntü" \
    --tab="Masaüstü" \
    --tab="Süper Tuşu" \
    --tab="Çeşitli" \
    --button="Seçimleri Uygula:2" \
    --button="Kapat:0"

RET_CODE=$?

if [ $RET_CODE -eq 2 ]; then
    # Panel Uygula
    if [ -f /tmp/meles_tweak_tab1.tmp ]; then
        P_POS=$(cat /tmp/meles_tweak_tab1.tmp | awk -F'|' '{print $1}')
        P_DOCK=$(cat /tmp/meles_tweak_tab1.tmp | awk -F'|' '{print $2}')
        bash "$0" --apply-panel "$P_POS" "$P_DOCK" &
    fi
    # Kompozitör Uygula
    if [ -f /tmp/meles_tweak_tab3.tmp ]; then
        K_ANIM=$(cat /tmp/meles_tweak_tab3.tmp | awk -F'|' '{print $1}')
        K_TILE=$(cat /tmp/meles_tweak_tab3.tmp | awk -F'|' '{print $2}')
        K_CENT=$(cat /tmp/meles_tweak_tab3.tmp | awk -F'|' '{print $3}')
        bash "$0" --apply-compositor "$K_ANIM" "$K_TILE" "$K_CENT" &
    fi
    # Görüntü Uygula
    if [ -f /tmp/meles_tweak_tab4.tmp ]; then
        D_DISP=$(cat /tmp/meles_tweak_tab4.tmp | awk -F'|' '{print $1}')
        D_RES=$(cat /tmp/meles_tweak_tab4.tmp | awk -F'|' '{print $2}')
        D_BRI=$(cat /tmp/meles_tweak_tab4.tmp | awk -F'|' '{print $3}')
        bash "$0" --apply-display "$D_DISP" "$D_RES" "$D_BRI" &
    fi
    # Masaüstü Uygula
    if [ -f /tmp/meles_tweak_tab5.tmp ]; then
        M_HOME=$(cat /tmp/meles_tweak_tab5.tmp | awk -F'|' '{print $1}')
        M_TRASH=$(cat /tmp/meles_tweak_tab5.tmp | awk -F'|' '{print $2}')
        M_SIZE=$(cat /tmp/meles_tweak_tab5.tmp | awk -F'|' '{print $3}')
        bash "$0" --apply-desktop "$M_HOME" "$M_TRASH" "$M_SIZE" &
    fi
    # Süper tuşu ayarı, notebook'un genel Uygula düğmesine de dahildir.
    if [ -f /tmp/meles_tweak_tab6.tmp ]; then
        M_SUPER=$(cat /tmp/meles_tweak_tab6.tmp | awk -F'|' '{print $1}')
        case "$M_SUPER" in
            "ArcMenu (Meles)") bash "$0" --apply-superkey arcmenu &
                ;;
            "GNOME Genel Bakış") bash "$0" --apply-superkey gnome &
                ;;
        esac
    fi
    # Çeşitli Uygula
    if [ -f /tmp/meles_tweak_tab7.tmp ]; then
        MISC_BT=$(cat /tmp/meles_tweak_tab7.tmp | awk -F'|' '{print $1}')
        MISC_HOST=$(cat /tmp/meles_tweak_tab7.tmp | awk -F'|' '{print $2}')
        bash "$0" --apply-misc "$MISC_BT" "$MISC_HOST" &
    fi
fi

# Geçici dosyaları temizle
rm -f /tmp/meles_tweak_tab*.tmp 2>/dev/null || true
exit 0
