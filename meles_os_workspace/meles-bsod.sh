#!/bin/bash

BLUE=$'\033[44;97m'
RESET=$'\033[0m'
BOLD=$'\033[1m'

printf '\033[2J\033[H'
printf '%s%s' "$BLUE" "$BOLD"
printf ' MELES OS - SISTEM BASLATMA HATASI\n\n'
printf 'Sistem acil moda gecti. Baslatilamayan birimler:\n\n'
systemctl --failed --no-legend --plain 2>&1 | head -n 8
printf '\nSon sistem hata kayitlari:\n\n'
journalctl -b -p err..emerg -n 10 --no-pager -o short-precise 2>&1
printf '\nHata gunlugu: journalctl -b -p err..emerg\n'
printf 'Kurtarma kabugu acilacak. Devam etmek icin Enter tusuna basin.\n'
printf '%s' "$RESET"

if [ -t 0 ]; then
    IFS= read -r -t 30 _
fi
