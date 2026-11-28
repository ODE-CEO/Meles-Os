#!/bin/bash
set -euo pipefail

if [[ "${1:-}" != "--run" && "${1:-}" != "--diagnostics" ]] &&
    ! command -v yad >/dev/null 2>&1; then
    printf 'YAD bulunamadi. Paket onarim araclari icin yad paketini kurun.\n' >&2
    exit 1
fi

if [[ "${1:-}" != "--run" && "${1:-}" != "--diagnostics" ]]; then
    ACTION=$(yad --list --title="Meles Sistem Onarımı" --center \
        --width=680 --height=360 --print-column=1 \
        --column="Komut:HD" --column="Onarım / Araç" \
        packages "Paket yapılandırma ve bağımlılık hatalarını düzelt" \
        boot "Boot yapılandırması ve initramfs dosyalarını yenile" \
        drivers "Ekran kartı ve donanım sürücülerini aç" \
        diagnostics "RAM, CPU, disk ve aygıt tanılamasını göster" \
        --button="Başlat:0" --button="Kapat:1") || exit 0

    [[ -n "$ACTION" ]] || exit 0
    if [[ "$ACTION" == "diagnostics" ]]; then
        exec "$0" --diagnostics
    elif [[ "$ACTION" == "drivers" ]]; then
        exec python3 /usr/local/bin/meles_glass_center.py
    fi

    if [[ "$EUID" -eq 0 ]]; then
        exec "$0" --run "$ACTION"
    fi

    if pkexec env \
        DISPLAY="${DISPLAY:-}" \
        XAUTHORITY="${XAUTHORITY:-}" \
        /usr/local/bin/meles-sistem-onarim.sh --run "$ACTION"; then
        STATUS=0
    else
        STATUS=$?
        yad --error --title="Meles Sistem Onarımı" --center \
            --text="Onarım işlemi başarısız oldu (kod: $STATUS).\nAyrıntılar: /var/log/meles-sistem-onarim.log"
    fi
    exit "$STATUS"
fi

if [[ "${1:-}" == "--diagnostics" ]]; then
    REPORT=$(mktemp)
    {
        printf '=== Bellek ===\n'
        free -h
        printf '\n=== En çok RAM kullanan işlemler ===\n'
        ps -eo pid,comm,rss,%cpu --sort=-rss | head -n 11
        printf '\n=== CPU ===\n'
        lscpu | grep -E 'Model name|CPU\\(s\\)|Thread|Socket' || true
        printf '\n=== Disk ===\n'
        df -h -x tmpfs -x devtmpfs
        printf '\n=== Grafik ve aygıtlar ===\n'
        lspci 2>/dev/null | grep -Ei 'vga|3d|display|network' || true
    } >"$REPORT"
    yad --text-info --title="Meles Sistem Tanılaması" --center \
        --width=760 --height=560 --filename="$REPORT" --button="Kapat:0"
    rm -f "$REPORT"
    exit 0
fi

[[ "$EUID" -eq 0 ]] || {
    printf 'Onarım işlemleri yönetici yetkisi gerektirir.\n' >&2
    exit 1
}

ACTION="${2:-}"
LOG="/var/log/meles-sistem-onarim.log"
exec > >(tee -a "$LOG") 2>&1

case "$ACTION" in
    packages)
        dpkg --configure -a
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get --fix-broken install -y
        ;;
    boot)
        update-initramfs -u -k all
        update-grub
        ;;
    *)
        printf 'Bilinmeyen onarım işlemi: %s\n' "$ACTION" >&2
        exit 2
        ;;
esac

printf 'İşlem başarıyla tamamlandı. Günlük: %s\n' "$LOG"
