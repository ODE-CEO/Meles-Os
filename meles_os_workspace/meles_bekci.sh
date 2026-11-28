#!/bin/bash
# ==============================================================================
# MELES OS: AKILLI BİLDİRİM VE SİSTEM BEKÇİSİ (SENTINEL DAEMON)
# Mimari: Vibe-Coding Standard | Motor: libnotify / D-Bus
# ==============================================================================

# Bildirim Gönderme Fonksiyonu 📢
bildir() {
    local baslik="$1"
    local mesaj="$2"
    local ikon="$3"
    local aciliyet="${4:-normal}"
    
    if command -v notify-send &>/dev/null; then
        notify-send -u "$aciliyet" -i "$ikon" -a "Meles Sistemi" "$baslik" "$mesaj"
    fi
}

# Durum Bayrakları (Spam engelleme kilidi) 🔒
ONCEKI_SARJ_DURUMU=""
UYARI_20_VERILDI=0
UYARI_10_VERILDI=0
RAM_UYARI_VERILDI=0
GUNCELLEME_SAYACI=0
SON_GUNCELLEME_SAYISI=-1

# Battery/RAM checks run every five minutes; cached package indexes are checked
# after ten minutes and then every six hours.
while true; do
    # --------------------------------------------------------------------------
    # 1. PİL VE ŞARJ KONTROLÜ ⚡🔋
    # --------------------------------------------------------------------------
    BAT_PATH=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
    
    if [ -n "$BAT_PATH" ] && [ -d "$BAT_PATH" ]; then
        STATUS=$(cat "$BAT_PATH/status" 2>/dev/null)
        CAPACITY=$(cat "$BAT_PATH/capacity" 2>/dev/null)

        # Şarj Durum Değişimi Algılama
        if [ "$STATUS" != "$ONCEKI_SARJ_DURUMU" ] && [ -n "$ONCEKI_SARJ_DURUMU" ]; then
            if [ "$STATUS" == "Charging" ]; then
                bildir "⚡ Şarj Cihazı Bağlandı" "Pil doluyor (%$CAPACITY). Yüksek performans modu aktif edilebilir." "battery-charging" "normal"
                UYARI_20_VERILDI=0
                UYARI_10_VERILDI=0
            elif [ "$STATUS" == "Discharging" ]; then
                bildir "🔋 Güç Kablosu Çıkarıldı" "Sistem pilden çalışıyor (%$CAPACITY)." "battery-caution" "normal"
            fi
        fi
        ONCEKI_SARJ_DURUMU="$STATUS"

        # Pil Düşük Seviye Uyarıları
        if [ "$STATUS" == "Discharging" ]; then
            if [ "$CAPACITY" -le 10 ] && [ "$UYARI_10_VERILDI" -eq 0 ]; then
                bildir "🚨 KRİTİK PİL SEVİYESİ!" "Kalan Şarj: %$CAPACITY. Cihaz kapanabilir, şarja takın!" "battery-caution" "critical"
                UYARI_10_VERILDI=1
                UYARI_20_VERILDI=1
            elif [ "$CAPACITY" -le 20 ] && [ "$UYARI_20_VERILDI" -eq 0 ]; then
                bildir "⚠️ Pil Azalıyor" "Kalan Şarj: %$CAPACITY. Güç tasarrufu önerilir." "battery-caution" "normal"
                UYARI_20_VERILDI=1
            elif [ "$CAPACITY" -gt 25 ]; then
                UYARI_20_VERILDI=0
                UYARI_10_VERILDI=0
            fi
        fi
    fi

    # --------------------------------------------------------------------------
    # 2. RAM TÜKETİM KONTROLÜ 🧠📊
    # --------------------------------------------------------------------------
    RAM_ORAN=$(awk '/MemTotal:/ {total=$2} /MemAvailable:/ {available=$2} END {if (total > 0) printf "%.0f", (total-available)/total*100}' /proc/meminfo)
    if [ "$RAM_ORAN" -ge 85 ] && [ "$RAM_UYARI_VERILDI" -eq 0 ]; then
        bildir "⚠️ Yüksek Bellek Kullanımı" "RAM kullanımı %$RAM_ORAN seviyesinde. Önbelleği temizleyebilirsiniz." "dialog-warning" "normal"
        RAM_UYARI_VERILDI=1
    elif [ "$RAM_ORAN" -lt 75 ]; then
        RAM_UYARI_VERILDI=0
    fi

    # --------------------------------------------------------------------------
    # 3. SESSİZ GÜNCELLEME KONTROLÜ 📦✨
    # --------------------------------------------------------------------------
    if [ "$GUNCELLEME_SAYACI" -eq 2 ] || [ "$GUNCELLEME_SAYACI" -ge 72 ]; then
        GUNCELLEME_SAYACI=0
        APT_UPDATES=$(apt list --upgradable 2>/dev/null |
            awk 'NR > 1 && NF { count++ } END { print count + 0 }')
        if [ "$APT_UPDATES" -gt 0 ] && [ "$APT_UPDATES" -ne "$SON_GUNCELLEME_SAYISI" ]; then
            bildir "Paket güncellemeleri hazır" "$APT_UPDATES paket güncellemesi bulundu. Güncelleme Merkezi'ni açın." "system-software-update" "normal"
        fi
        SON_GUNCELLEME_SAYISI="$APT_UPDATES"
    fi

    GUNCELLEME_SAYACI=$((GUNCELLEME_SAYACI + 1))
    sleep 300
done
