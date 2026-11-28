#!/bin/bash
# ==============================================================================
# PROJE ADI: Meles OS ISO Derleme Betiği (BETA Edition - Ultimate Boot Update)
# GELİŞTİRİCİ: Yağız & Kaan | Mimari: Vibe-Coding Standard
# ==============================================================================
set -e

export ASIL_DIZIN="$(pwd)"
PROJE_DIZINI="$ASIL_DIZIN/../meles_os_new_a/source_code"
LOG_DOSYASI="$ASIL_DIZIN/meles_build_log.txt"

hata_yakala() {
    echo -e "\e[31m[-] KRİTİK HATA: Süreç $(caller) satırında tıkandı.\e[0m"
    exit 1
}
trap hata_yakala ERR
exec > >(tee -a "$LOG_DOSYASI") 2>&1

echo ">>> [1/11] Sistem paketleri ve araçlar doğrulanıyor..."
apt update -qq
apt install -y live-build debootstrap curl wget coreutils imagemagick unzip zip fonts-dejavu-core syslinux-common -qq

echo ">>> [2/11] Çalışma alanı inşa ediliyor..."
mkdir -p "$PROJE_DIZINI"
cd "$PROJE_DIZINI"

echo ">>> [3/11] Şantiye temizleniyor..."
lb clean --purge > /dev/null 2>&1 || true
lb clean > /dev/null 2>&1 || true

echo ">>> [4/11] Meles OS modülleri yükleniyor..."
source "$ASIL_DIZIN/01_ayarlar_ve_paketler.sh"
source "$ASIL_DIZIN/02_kancalar_ve_boot.sh"
source "$ASIL_DIZIN/03_meles_arayuz_ve_sistem.sh"
source "$ASIL_DIZIN/04_meles_uygulamalar_ve_ai.sh"

echo ">>> [5/11] Harici uygulama katmanı (app.sh) kontrol ediliyor..."
if [ -f "$ASIL_DIZIN/app.sh" ]; then
    bash "$ASIL_DIZIN/app.sh"
fi

echo ">>> [6/11] Boot ekranı Meles markasıyla imzalanıyor (UEFI & BIOS Dual Destek)..."

# --- UEFI (GRUB) HİBRİT YAPILANDIRMASI ---
mkdir -p config/bootloaders/grub-pc config/bootloaders/grub-efi
cat << 'GRUB_EOF' > config/bootloaders/grub-pc/grub.cfg
insmod all_video
insmod png
set gfxmode=auto
insmod gfxterm
terminal_output gfxterm
loadfont unicode
loadfont $prefix/meles/meles-title.pf2
loadfont $prefix/meles/meles-brand.pf2
loadfont $prefix/meles/meles-menu.pf2
set theme=$prefix/meles/theme.txt
set default=0
set timeout=15
set timeout_style=menu

menuentry "1 - Live Oturum (RAM'den calistir)" --class meles {
    linux /live/vmlinuz boot=live components toram locales=tr_TR.UTF-8 keyboard-layouts=tr quiet splash panic_print=0x3f meles_mode=live live-config.user-fullname="Meles_Kullanicisi" live-config.username=meles
    initrd /live/initrd.img
}

menuentry "2 - Dogrudan kuruluma gec" --class meles {
    linux /live/vmlinuz boot=live components locales=tr_TR.UTF-8 keyboard-layouts=tr quiet splash panic_print=0x3f meles_mode=install systemd.unit=multi-user.target live-config.user-fullname="Meles_Kullanicisi" live-config.username=meles
    initrd /live/initrd.img
}

menuentry "3 - Guvenli mod (Live, nomodeset)" --class meles {
    linux /live/vmlinuz boot=live components locales=tr_TR.UTF-8 keyboard-layouts=tr nomodeset noapic noacpi panic_print=0x3f meles_mode=live live-config.user-fullname="Meles_Kullanicisi" live-config.username=meles plymouth.enable=0
    initrd /live/initrd.img
}

menuentry "4 - BIOS / UEFI ayarlarina don" --class meles {
    if [ "$grub_platform" = "efi" ]; then
        fwsetup
    else
        echo "Yeniden baslatiliyor. Firmware ayarlari icin acilista BIOS tusuna basin."
        sleep 3
        reboot
    fi
}
GRUB_EOF

cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-pc/loopback.cfg || true
cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-efi/loopback.cfg || true

cat << 'THEME_EOF' > config/bootloaders/grub-pc/theme.txt
desktop-image: "splash.png"
title-text: ""

+ label {
    text = "M"
    font = "Meles Title Bold 42"
    color = "#f4f7ff"
    align = "center"
    left = 44%
    top = 7%
    width = 12%
    height = 60
}

+ label {
    text = "MELES OS"
    font = "Meles Brand Bold 28"
    color = "#f4f7ff"
    align = "center"
    left = 30%
    top = 16%
    width = 40%
    height = 48
}

+ label {
    text = "26B40 SIFIR  -  Canli oturum veya kurulum secin"
    font = "Meles Menu Regular 18"
    color = "#a9bad1"
    align = "center"
    left = 25%
    top = 25%
    width = 50%
    height = 32
}

+ boot_menu {
    left = 10%
    top = 34%
    width = 80%
    height = 52%
    item_font = "Meles Menu Regular 18"
    item_color = "#dce7f5"
    selected_item_color = "#55adff"
    selected_item_pixmap = "selected.png"
    item_height = 44
    item_padding = 4
    item_spacing = 3
    scrollbar = false
}
THEME_EOF
convert -size 960x44 xc:none -fill '#245edb' \
    -draw 'roundrectangle 0,0 959,43 12,12' \
    -type TrueColorMatte -depth 8 \
    PNG32:config/bootloaders/grub-pc/selected.png
grub-mkfont --size=42 --name="Meles Title" \
    --output=config/bootloaders/grub-pc/meles-title.pf2 \
    /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
grub-mkfont --size=28 --name="Meles Brand" \
    --output=config/bootloaders/grub-pc/meles-brand.pf2 \
    /usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf
grub-mkfont --size=18 --name="Meles Menu" \
    --output=config/bootloaders/grub-pc/meles-menu.pf2 \
    /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf
cp config/bootloaders/grub-pc/grub.cfg config/bootloaders/grub-efi/grub.cfg || true
cp config/bootloaders/grub-pc/theme.txt config/bootloaders/grub-efi/theme.txt || true
cp config/bootloaders/grub-pc/selected.png config/bootloaders/grub-efi/selected.png
cp config/bootloaders/grub-pc/meles-title.pf2 config/bootloaders/grub-efi/meles-title.pf2
cp config/bootloaders/grub-pc/meles-brand.pf2 config/bootloaders/grub-efi/meles-brand.pf2
cp config/bootloaders/grub-pc/meles-menu.pf2 config/bootloaders/grub-efi/meles-menu.pf2

# --- LEGACY BIOS (ISOLINUX) YAPILANDIRMASI ---
mkdir -p config/bootloaders/isolinux
cat << 'ISO_EOF' > config/bootloaders/isolinux/menu.cfg
menu hshift 0
menu width 82
menu title MELES OS 26B40 SIFIR - BOOT
menu background splash.png
menu color title * #FF55ADFF *
menu color border * #00000000 #00000000 none
menu color sel * #FF05080F #FF55ADFF none
menu color unsel * #FFDCE7F5 * none

label live
    menu label 1 - Live Oturum (RAM'den calistir)
    kernel /live/vmlinuz
    append initrd=/live/initrd.img boot=live components toram locales=tr_TR.UTF-8 keyboard-layouts=tr quiet splash panic_print=0x3f meles_mode=live live-config.user-fullname="Meles_Kullanicisi" live-config.username=meles

label install
    menu label 2 - Dogrudan kuruluma gec
    kernel /live/vmlinuz
    append initrd=/live/initrd.img boot=live components locales=tr_TR.UTF-8 keyboard-layouts=tr quiet splash panic_print=0x3f meles_mode=install systemd.unit=multi-user.target live-config.user-fullname="Meles_Kullanicisi" live-config.username=meles

label failsafe
    menu label 3 - Guvenli mod (Live, nomodeset)
    kernel /live/vmlinuz
    append initrd=/live/initrd.img boot=live components locales=tr_TR.UTF-8 keyboard-layouts=tr nomodeset noapic noacpi panic_print=0x3f meles_mode=live live-config.user-fullname="Meles_Kullanicisi" live-config.username=meles plymouth.enable=0

label firmware
    menu label 4 - BIOS / UEFI ayarlarina don (yeniden baslat)
    kernel reboot.c32
ISO_EOF

cp /usr/lib/syslinux/modules/bios/reboot.c32 config/bootloaders/isolinux/reboot.c32

echo ">>> [7/11] Varlıklar (Assets) doğrulanıyor..."
mkdir -p config/includes.chroot/usr/share/backgrounds/meles

echo ">>> [8/11] Eski ISO dosyaları temizleniyor..."
rm -f "$ASIL_DIZIN/meles-os-beta.iso"
rm -f live-image-*.iso

echo ">>> [9/11] Derleme (lb build) başlatılıyor..."
# Keep local prototypes and test pages in the workspace, but never stage them
# into the live filesystem or ISO, including leftovers from earlier builds.
find config/includes.chroot -type f \( \
    -name 'Meles Kütüphane.html' -o \
    -name 'Meles formatter+.html' -o \
    -name 'melesgenelai.py' -o \
    -name 'Meles Kod.py' -o \
    -name 'Meles Kodlama.py' -o \
    -name 'Meles Oyun.html' -o \
    -name 'meles.html' -o \
    -name 'astıra 12.0 hd zom.html' -o \
    -name 'melesharita.html' -o \
    -name 'meles_menu.sh' -o \
    -name 'meles-oyun-modu.sh' -o \
    -name 'melesai.py' -o \
    -name 'Meles_AI.desktop' \
\) -delete

lb build

echo ">>> [10/11] ISO dosyası ana dizine taşınıyor..."
ISO_DOSYASI=$(ls live-image-*.iso 2>/dev/null | head -n 1)

if [ -n "$ISO_DOSYASI" ] && [ -f "$ISO_DOSYASI" ]; then
    mv "$ISO_DOSYASI" "$ASIL_DIZIN/meles-os-beta.iso"
fi

if [ -f "$ASIL_DIZIN/meles-os-beta.iso" ]; then
    echo -e "\e[32m[+][+][+] Meles OS Beta Başarıyla İnşa Edildi! Çıktı: $ASIL_DIZIN/meles-os-beta.iso\e[0m"
else
    echo -e "\e[31m[-] HATA: ISO dosyası üretilemedi veya taşınamadı.\e[0m"
    exit 1
fi

echo ">>> [11/11] Şantiye imha ediliyor..."
cd "$ASIL_DIZIN"
rm -rf "$PROJE_DIZINI"
