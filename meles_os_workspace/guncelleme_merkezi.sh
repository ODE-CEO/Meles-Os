#!/bin/bash

set -u

SCRIPT_PATH="$(readlink -f "$0")"
TITLE="Meles OS Güncelleme Merkezi"

if [[ "${1:-}" == "--refresh-index" || "${1:-}" == "--apply-upgrades" ]]; then
    if [[ "$EUID" -ne 0 ]]; then
        printf 'Paket güncellemeleri yönetici yetkisi gerektirir.\n' >&2
        exit 1
    fi

    apt-get update -qq || exit $?
    if [[ "$1" == "--apply-upgrades" ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get \
            -o Dpkg::Options::=--force-confdef \
            -o Dpkg::Options::=--force-confold \
            upgrade -y
        exit $?
    fi
    exit 0
fi

if ! command -v yad >/dev/null 2>&1; then
    printf 'Hata: YAD yüklü değil. Paket yükleyici olarak Synaptic kullanılabilir.\n' >&2
    exit 1
fi

run_privileged() {
    local mode="$1"
    local message="$2"
    local log_file status_file runner status
    log_file=$(mktemp)
    status_file=$(mktemp)

    if command -v pkexec >/dev/null 2>&1; then
        (
            pkexec env \
                DISPLAY="${DISPLAY:-}" \
                XAUTHORITY="${XAUTHORITY:-}" \
                DEBIAN_FRONTEND=noninteractive \
                /bin/bash "$SCRIPT_PATH" "$mode" >"$log_file" 2>&1
            printf '%s\n' "$?" >"$status_file"
        ) &
        runner=$!
    else
        yad --error --title="$TITLE" --center \
            --text="Grafiksel yönetici yetkilendirmesi (pkexec) bulunamadı."
        rm -f "$log_file" "$status_file"
        return 1
    fi

    (
        while [[ ! -s "$status_file" ]]; do
            printf '# %s\n' "$message"
            sleep 1
        done
        printf '100\n# İşlem tamamlandı.\n'
    ) | yad --progress --title="$TITLE" --center --width=480 \
        --pulsate --auto-close --no-buttons --text="$message"

    wait "$runner"
    status=$(cat "$status_file" 2>/dev/null || printf '1')
    if [[ "$status" != "0" ]]; then
        yad --text-info --title="Güncelleme Hatası" --center \
            --width=760 --height=500 --filename="$log_file" \
            --button="Kapat:0"
    else
        yad --info --title="$TITLE" --center \
            --text="Paket işlemi başarıyla tamamlandı.\nKişisel dosyalarınız ve kullanıcı ayarlarınız değiştirilmedi."
    fi

    rm -f "$log_file" "$status_file"
    [[ "$status" == "0" ]]
}

while true; do
    UPGRADABLE=$(apt list --upgradable 2>/dev/null |
        sed '1d' | cut -d/ -f1 | sed '/^$/d')
    PACKAGE_COUNT=$(printf '%s\n' "$UPGRADABLE" | sed '/^$/d' | wc -l)
    if [[ "$PACKAGE_COUNT" -eq 0 ]]; then
        UPDATE_STATUS="APT listelerinde bekleyen paket güncellemesi görünmüyor."
    else
        UPDATE_STATUS="$PACKAGE_COUNT paket güncellemesi hazır."
    fi

    DETAILS="$UPDATE_STATUS

Güncellemeler APT paket depolarından yüklenir. ISO kurulumu, bölümleme ve kullanıcı dosyalarına müdahale yapılmaz."
    yad --form --title="$TITLE" --center --width=650 \
        --text="$DETAILS" \
        --field="Bekleyen paket güncellemesi:":RO "$PACKAGE_COUNT" \
        --button="Güncelleme denetle:10" \
        --button="Paketleri güncelle:20" \
        --button="Kapat:0"
    result=$?

    case "$result" in
        10)
            run_privileged --refresh-index "APT paket listeleri yenileniyor..." || true
            ;;
        20)
            if [[ "$PACKAGE_COUNT" -eq 0 ]]; then
                if run_privileged --refresh-index "APT paket listeleri yenileniyor..."; then
                    continue
                fi
            else
                yad --question --title="$TITLE" --center \
                    --text="$PACKAGE_COUNT paket apt-get upgrade ile kurulacak. Kişisel dosyalar ve kullanıcı ayarları korunur. Devam edilsin?" \
                    --button="İptal:1" --button="Güncelle:0" || continue
            fi
            run_privileged --apply-upgrades "Paket güncellemeleri indiriliyor ve kuruluyor..." || true
            ;;
        *)
            exit 0
            ;;
    esac
done
