#!/bin/bash
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "Bu işlem pkexec ile yönetici yetkisiyle çalıştırılmalıdır." >&2
    exit 1
fi

case "${1:-}" in
    install-drivers)
        if ! command -v lspci >/dev/null 2>&1; then
            echo "Donanım taraması için pciutils/lspci kurulu değil." >&2
            exit 1
        fi
        DEVICES=$(lspci -nn | grep -Ei 'VGA|3D controller|Display controller' || true)
        if [ -z "$DEVICES" ]; then
            echo "Ekran kartı algılanamadı; sürücü kurulumu iptal edildi." >&2
            exit 1
        fi

        PACKAGES=()
        if grep -Eqi 'NVIDIA|10de:' <<< "$DEVICES"; then
            PACKAGES+=(nvidia-driver firmware-misc-nonfree)
        fi
        if grep -Eqi 'AMD|ATI|1002:' <<< "$DEVICES"; then
            PACKAGES+=(firmware-amd-graphics mesa-vulkan-drivers xserver-xorg-video-amdgpu)
        fi
        if grep -Eqi 'Intel|8086:' <<< "$DEVICES"; then
            PACKAGES+=(mesa-vulkan-drivers intel-media-va-driver)
        fi
        if [ "${#PACKAGES[@]}" -eq 0 ]; then
            echo "Algılanan ekran kartı için desteklenen paket profili bulunamadı." >&2
            exit 1
        fi

        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y "${PACKAGES[@]}"
        echo "Sürücü paketleri kuruldu. NVIDIA gibi çekirdek sürücülerinde yeniden başlatma gerekebilir."
        ;;
    memory-on)
        MISSING=()
        for package in zram-tools earlyoom; do
            if ! dpkg-query -W -f='${db:Status-Status}' "$package" 2>/dev/null |
                grep -Fxq installed; then
                MISSING+=("$package")
            fi
        done
        if [ "${#MISSING[@]}" -gt 0 ]; then
            apt-get update
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${MISSING[@]}"
        fi
        systemctl enable --now zramswap.service earlyoom.service
        echo "ZRAM ve Early OOM etkinleştirildi."
        ;;
    memory-off)
        systemctl disable --now zramswap.service earlyoom.service
        echo "ZRAM ve Early OOM devre dışı bırakıldı."
        ;;
    *)
        echo "Kullanım: $0 {install-drivers|memory-on|memory-off}" >&2
        exit 2
        ;;
esac
