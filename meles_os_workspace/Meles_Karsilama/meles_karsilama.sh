#!/bin/bash
# ==============================================================================
# MELES OS: KARŞILAMA VE BAŞLANGIÇ MERKEZİ (FULL INTEGRATED EDITION)
# Standart: Saf Bash + YAD/GTK3 | Tam Koyu Mod & Eksiksiz Entegrasyon
# ==============================================================================

export GTK_THEME="Adwaita:dark"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BELGELER_DIR="$SCRIPT_DIR/belgeler"
AUTOSTART_DIR="$HOME/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/meles-karsilama.desktop"
ILK_ACILIS=false

if [ "${1:-}" == "--first-run" ]; then
    ILK_ACILIS=true
    if [ -f "$HOME/.local/state/meles/welcome-shown" ]; then
        rm -f "$AUTOSTART_FILE"
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# 1. ENTEGRE AKSİYONLAR VE BUTON ÇAĞRICILARI
# ------------------------------------------------------------------------------

# Akıllı Belge Açıcı (Türkçe karakter ve soru işareti toleranslı)
belge_ac() {
    local hedef="$1"
    local desen="$2"
    if [ -f "$hedef" ]; then
        xdg-open "$hedef" 2>/dev/null &
    else
        local alternatif=$(ls "$BELGELER_DIR"/$desen 2>/dev/null | head -n 1)
        if [ -n "$alternatif" ] && [ -f "$alternatif" ]; then
            xdg-open "$alternatif" 2>/dev/null &
        else
            yad --warning --title="Belge Bulunamadı" \
                --text="Belge dosyası tespit edilemedi:\n$hedef\n\nLütfen 'belgeler' klasörünü kontrol edin." \
                --center --button="Tamam:0"
        fi
    fi
}

# [ 1 ] Meles OS Nedir? Belgesi
if [ "$1" == "--act-1" ]; then
    belge_ac "$BELGELER_DIR/Melesnedir?.odt" "*Melesnedir*"
    exit 0

# [ 2 ] Kullanım Kılavuzu Belgesi
elif [ "$1" == "--act-2" ]; then
    belge_ac "$BELGELER_DIR/Kılavuz.odt" "*K*lavuz*"
    exit 0

# [ 3 ] GitHub Deposu
elif [ "$1" == "--act-3" ]; then
    xdg-open "https://github.com/ODE-CEO/Meles-Os" 2>/dev/null &
    exit 0

# [ 4 ] Meles Araçlar Merkezi
elif [ "$1" == "--act-4" ]; then
    if [ -f "$SCRIPT_DIR/meles_araclar.sh" ]; then
        bash "$SCRIPT_DIR/meles_araclar.sh" &
    elif command -v meles-araclar &>/dev/null; then
        meles-araclar &
    else
        yad --info --text="Meles Araçlar Merkezi başlatılıyor..." --center --timeout=2 --no-buttons
    fi
    exit 0

# [ 5 ] Özelleştirme ve İnce Ayar
elif [ "$1" == "--act-5" ]; then
    if [ -f "$SCRIPT_DIR/meles_ince_ayar.sh" ]; then
        bash "$SCRIPT_DIR/meles_ince_ayar.sh" &
    elif command -v meles-ince-ayar &>/dev/null; then
        meles-ince-ayar &
    else
        yad --info --text="İnce Ayar ve Özelleştirme başlatılıyor..." --center --timeout=2 --no-buttons
    fi
    exit 0

# [ 6 ] Discord Topluluğu
elif [ "$1" == "--act-6" ]; then
    xdg-open "https://discord.gg" 2>/dev/null &
    exit 0

# [ 7 ] Tanıtım Videoları
elif [ "$1" == "--act-7" ]; then
    xdg-open "https://youtube.com" 2>/dev/null &
    exit 0

# [ 8 ] Katkıda Bulunun (Destek Belgesi)
elif [ "$1" == "--act-8" ]; then
    belge_ac "$BELGELER_DIR/destek.odt" "*destek*"
    exit 0

# [ 9 ] Uygulamalar Kurun (Mağaza & Paket Yöneticisi)
elif [ "$1" == "--act-9" ]; then
    if command -v synaptic &>/dev/null; then
        synaptic-pkexec &
    elif command -v gnome-software &>/dev/null; then
        gnome-software &
    elif [ -f "$SCRIPT_DIR/meles_araclar.sh" ]; then
        bash "$SCRIPT_DIR/meles_araclar.sh" &
    else
        yad --info --text="Paket ve Uygulama Yöneticisi başlatılıyor..." --center --timeout=2 --no-buttons
    fi
    exit 0

# [ 10 ] İşletim Sistemi Turu
elif [ "$1" == "--act-10" ]; then
    if [ -f "$SCRIPT_DIR/meles_tur.sh" ]; then
        bash "$SCRIPT_DIR/meles_tur.sh" &
    else
        yad --info --text="Meles OS Turu başlatılıyor..." --center --timeout=2 --no-buttons
    fi
    exit 0

# Hakkında Penceresi
elif [ "$1" == "--act-hakkinda" ]; then
    yad --about --title="Meles OS Hakkında" \
        --name="Meles OS" \
        --version="2026.08 Titanium" \
        --comments="Debian Tabanlı Modern, Hafif ve Güçlü İşletim Sistemi Dağıtımı" \
        --copyright="© 2026 Meles OS Ekibi" \
        --website="https://github.com/ODE-CEO/Meles-Os" \
        --center
    exit 0
fi

# ------------------------------------------------------------------------------
# 3. ÇİFT SEKME VE SİMETRİK YAD YERLEŞİMİ (1-5 SOL, 6-10 SAĞ)
# ------------------------------------------------------------------------------
KEY=$RANDOM

# SEKME 1: HOŞ GELDİNİZ (ORTALANMIŞ M LOGOSU VE DENGELİ SÜTUNLAR)
yad --plug=$KEY --tabnum=1 --form --columns=2 \
    --text="<span font='32' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             MELES OS BAŞLANGIÇ MERKEZİ</b></span>\n<span font='10' color='#94a3b8'>       Sisteminizi yapılandırmak, belgeleri incelemek veya araçları açmak için seçin:</span>\n" \
    --field="  [ 1 ]  Meles OS Nedir?:FBTN" "bash \"$0\" --act-1" \
    --field="  [ 2 ]  Kullanım Kılavuzu:FBTN" "bash \"$0\" --act-2" \
    --field="  [ 3 ]  GitHub Adresi:FBTN" "bash \"$0\" --act-3" \
    --field="  [ 4 ]  Meles Araçları:FBTN" "bash \"$0\" --act-4" \
    --field="  [ 5 ]  Özelleştirme ve Ayarlar:FBTN" "bash \"$0\" --act-5" \
    --field="":LBL "" \
    --field="  [ 6 ]  Discord Topluluğu:FBTN" "bash \"$0\" --act-6" \
    --field="  [ 7 ]  Tanıtım Videoları:FBTN" "bash \"$0\" --act-7" \
    --field="  [ 8 ]  Katkıda Bulunun:FBTN" "bash \"$0\" --act-8" \
    --field="  [ 9 ]  Uygulamalar Kurun:FBTN" "bash \"$0\" --act-9" \
    --field="  [ 10 ] İşletim Sistemi Turu:FBTN" "bash \"$0\" --act-10" \
    >/dev/null 2>&1 &

# SEKME 2: SİSTEM HAKKINDA BİLGİ
KERNEL_VER=$(uname -r)
ARCH_VER=$(uname -m)
UPTIME_VAL=$(uptime -p 2>/dev/null || echo "Bilinmiyor")

yad --plug=$KEY --tabnum=2 --form \
    --text="<span font='32' weight='heavy' color='#38bdf8'><b>        M</b></span>\n<span font='14' weight='bold' color='#f1f5f9'><b>             SİSTEM VE MİMARİ BİLGİSİ</b></span>\n<span font='10' color='#94a3b8'>       Meles OS çekirdek ve donanım özeti:</span>\n" \
    --field="İşletim Sistemi:":RO "Meles OS" \
    --field="Sürüm / Kod Adı:":RO "2026.08 Titanium" \
    --field="Taban Altyapı:":RO "Debian GNU/Linux" \
    --field="Sistem Mimarisi:":RO "$ARCH_VER" \
    --field="Linux Çekirdeği:":RO "$KERNEL_VER" \
    --field="Çalışma Süresi:":RO "$UPTIME_VAL" \
    --field="Meles Proje Detayları:FBTN" "bash \"$0\" --act-hakkinda" \
    &

# ------------------------------------------------------------------------------
# 4. ANA PENCERE MOTORU (TAM KOYU MOD)
# ------------------------------------------------------------------------------
yad --notebook --key=$KEY --tab-pos=top \
    --title="Meles OS Karşılama Merkezi" \
    --width=760 --height=530 --center \
    --tab="Hoş Geldiniz" \
    --tab="Hakkında" \
    --button="Hakkında:2" \
    --button="Kapat:0"

RET_CODE=$?

if [ $RET_CODE -eq 2 ]; then
    bash "$0" --act-hakkinda &
fi

if [ "$ILK_ACILIS" == "true" ]; then
    mkdir -p "$HOME/.local/state/meles"
    touch "$HOME/.local/state/meles/welcome-shown"
    rm -f "$AUTOSTART_FILE"
fi

exit 0
