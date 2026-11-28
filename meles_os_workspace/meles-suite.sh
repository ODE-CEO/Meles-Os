#!/usr/bin/env bash
# ==============================================================================
# Meles OS Araç Paketi (Meles Suite for Debian)
# Araçlar: Yazılım Doktoru | Meles Terminal | Meles TV
# ==============================================================================

# Renk Tanımlamaları
MBLUE='\033[1;34m'
MCYAN='\033[1;36m'
MGREEN='\033[1;32m'
MYELLOW='\033[1;33m'
MRED='\033[1;31m'
MRESET='\033[0m'

# Başlık Çizme Fonksiyonu
meles_header() {
    clear
    echo -e "${MCYAN}============================================================${MRESET}"
    echo -e "${MBLUE}   __  __ _____ _      _____ _____    ____  ____  ${MRESET}"
    echo -e "${MBLUE}  |  \/  |  ___| |    |  ___/  ___|  / __ \/ ___| ${MRESET}"
    echo -e "${MBLUE}  | |\/| | |__ | |    | |__ \ \--.  | |  | \ \--. ${MRESET}"
    echo -e "${MBLUE}  | |  | |  __|| |    |  __| \--. \ | |  | |\--. \ ${MRESET}"
    echo -e "${MBLUE}  | |  | | |___| |____| |___/\__/ / | |__| /\__/ / ${MRESET}"
    echo -e "${MBLUE}  |_|  |_|_____|_____/|____/\____/   \____/\____/  ${MRESET}"
    echo -e "${MCYAN}============================================================${MRESET}"
    echo -e "${MYELLOW}       Meles OS Sistem Araçları ve TV Platformu        ${MRESET}"
    echo -e "${MCYAN}============================================================${MRESET}"
    echo ""
}

# ==============================================================================
# 1. MELES OS YAZILIM DOKTORU
# ==============================================================================
meles_doctor() {
    meles_header
    echo -e "${MYELLOW}[+] Meles OS Yazılım Doktoru Başlatılıyor...${MRESET}\n"

    echo -e "${MCYAN}[1/5] İnternet Bağlantısı Kontrol Ediliyor...${MRESET}"
    if ping -c 1 debian.org &> /dev/null; then
        echo -e "${MGREEN}  -> Bağlantı aktif ve stabil.${MRESET}"
    else
        echo -e "${MRED}  -> UYARI: İnternet bağlantısı ulaşılamaz durumda!${MRESET}"
    fi
    sleep 1

    echo -e "\n${MCYAN}[2/5] Debian Paket Veritabanı (dpkg) Denetleniyor...${MRESET}"
    if dpkg --audit | grep -q .; then
        echo -e "${MRED}  -> Bozuk veya yarım kalmış paketler tespit edildi! Onarım deneniyor...${MRESET}"
        sudo dpkg --configure -a
    else
        echo -e "${MGREEN}  -> dpkg veritabanı sağlıklı.${MRESET}"
    fi
    sleep 1

    echo -e "\n${MCYAN}[3/5] APT Bağımlılıkları Kontrol Ediliyor...${MRESET}"
    if ! sudo apt-get check &> /dev/null; then
        echo -e "${MYELLOW}  -> Bağımlılık hatası bulundu. Fix-broken çalıştırılıyor...${MRESET}"
        sudo apt-get install -f -y
    else
        echo -e "${MGREEN}  -> APT bağımlılık zinciri sorunsuz.${MRESET}"
    fi
    sleep 1

    echo -e "\n${MCYAN}[4/5] Sistem Önbelleği Temizliği...${MRESET}"
    sudo apt-get autoremove -y > /dev/null 2>&1
    sudo apt-get autoclean -y > /dev/null 2>&1
    echo -e "${MGREEN}  -> Gereksiz bağımlılıklar ve eski paket önbellekleri temizlendi.${MRESET}"
    sleep 1

    echo -e "\n${MCYAN}[5/5] Disk Kullanım Özetiniz:${MRESET}"
    df -h / | awk 'NR==2 {print "  -> Toplam Disk: " $2 " | Kullanılan: " $3 " (" $5 ") | Boş: " $4}'

    echo -e "\n${MGREEN}[✓] Yazılım Doktoru tarama ve bakım işlemini tamamladı!${MRESET}"
    read -n 1 -s -r -p "Ana menüye dönmek için bir tuşa basın..."
}

# ==============================================================================
# 2. MELES OS TERMINAL
# ==============================================================================
meles_terminal() {
    meles_header
    echo -e "${MGREEN}Meles OS Temalı Özel Oturum Başına Hoş Geldiniz.${MRESET}"
    echo -e "${MYELLOW}Çıkış yapmak ve ana menüye dönmek için 'exit' veya 'q' yazın.${MRESET}\n"

    # Minimal sistem bilgisi başlığı
    local kernel_ver=$(uname -r)
    local mem_usage=$(free -m | awk '/Mem:/ {print $3 "/" $2 " MB"}')
    echo -e "${MBLUE}------------------------------------------------------------${MRESET}"
    echo -e "  ${MCYAN}İşletim Sistemi :${MRESET} Meles OS (Debian Tabanlı)"
    echo -e "  ${MCYAN}Çekirdek (Kernel):${MRESET} ${kernel_ver}"
    echo -e "  ${MCYAN}RAM Kullanımı   :${MRESET} ${mem_usage}"
    echo -e "${MBLUE}------------------------------------------------------------${MRESET}\n"

    # Meles terminal döngüsü
    while true; do
        echo -ne "${MCYAN}meles@os${MRESET}:${MYELLOW}~${MRESET}$ "
        read -r cmd
        case "$cmd" in
            exit|q|quit)
                break
                ;;
            "")
                continue
                ;;
            *)
                # Girilen komutu çalıştır
                eval "$cmd"
                ;;
        esac
    done
}

# ==============================================================================
# 3. MELES TV (İnternetten Canlı Akış Çekme)
# ==============================================================================
meles_tv() {
    meles_header
    echo -e "${MYELLOW}[+] Meles TV - Canlı İnternet TV Modülü${MRESET}\n"

    # Video oynatıcı kontrolü (Önce mpv, yoksa vlc)
    local PLAYER=""
    if command -v mpv &> /dev/null; then
        PLAYER="mpv --quiet"
    elif command -v vlc &> /dev/null; then
        PLAYER="vlc --quiet"
    else
        echo -e "${MRED}[!] Meles TV için 'mpv' veya 'vlc' oynatıcı gereklidir.${MRESET}"
        echo -e "${MYELLOW}Yükleniyor: sudo apt update && sudo apt install -y mpv${MRESET}"
        sudo apt-get update && sudo apt-get install -y mpv
        PLAYER="mpv --quiet"
    fi

    echo -e "${MCYAN}İzlemek istediğiniz kanalı seçin:${MRESET}"
    echo -e "  ${MGREEN}1)${MRESET} TRT 1 (Canlı HLS Akışı)"
    echo -e "  ${MGREEN}2)${MRESET} TRT Haber"
    echo -e "  ${MGREEN}3)${MRESET} TRT Belgesel"
    echo -e "  ${MGREEN}4)${MRESET} NASA TV (Uluslararası HD Yayın)"
    echo -e "  ${MGREEN}5)${MRESET} Özel M3U8 / HLS Yayın URL'si Gir"
    echo -e "  ${MGREEN}0)${MRESET} Ana Menüye Dön"
    echo ""
    read -p "Seçiminiz [0-5]: " tv_secim

    case "$tv_secim" in
        1)
            echo -e "${MYELLOW}TRT 1 yükleniyor... (Kapatmak için video penceresinde Q tuşuna basın)${MRESET}"
            $PLAYER "https://tv-trt1.medya.trt.com.tr/master.m3u8"
            ;;
        2)
            echo -e "${MYELLOW}TRT Haber yükleniyor...${MRESET}"
            $PLAYER "https://tv-trthaber.medya.trt.com.tr/master.m3u8"
            ;;
        3)
            echo -e "${MYELLOW}TRT Belgesel yükleniyor...${MRESET}"
            $PLAYER "https://tv-trtbelgesel.medya.trt.com.tr/master.m3u8"
            ;;
        4)
            echo -e "${MYELLOW}NASA TV (Akış) yükleniyor...${MRESET}"
            $PLAYER "https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8"
            ;;
        5)
            read -p "Yayın Linkini (M3U8 / HLS) yapıştırın: " custom_url
            if [[ -n "$custom_url" ]]; then
                echo -e "${MYELLOW}Yayın açılıyor...${MRESET}"
                $PLAYER "$custom_url"
            else
                echo -e "${MRED}Geçersiz URL.${MRESET}"
                sleep 1
            fi
            ;;
        0)
            return
            ;;
        *)
            echo -e "${MRED}Geçersiz seçim!${MRESET}"
            sleep 1
            ;;
    esac
}

# ==============================================================================
# ANA MENÜ DÖNGÜSÜ
# ==============================================================================
while true; do
    meles_header
    echo -e "  ${MGREEN}1)${MRESET} Meles OS Yazılım Doktoru (Sistem Bakım & Onarım)"
    echo -e "  ${MGREEN}2)${MRESET} Meles OS Terminal (Özel Kabuk Arayüzü)"
    echo -e "  ${MGREEN}3)${MRESET} Meles TV (İnternet TV & Akış Oynatıcı)"
    echo -e "  ${MRED}q)${MRESET} Çıkış"
    echo ""
    read -p "Meles OS Araç Seçimi [1-3/q]: " main_choice

    case "$main_choice" in
        1) meles_doctor ;;
        2) meles_terminal ;;
        3) meles_tv ;;
        q|Q)
            echo -e "\n${MGREEN}Meles OS Suite kapatıldı. İyi çalışmalar!${MRESET}"
            exit 0
            ;;
        *)
            echo -e "${MRED}Geçersiz seçenek, lütfen tekrar deneyin.${MRESET}"
            sleep 1
            ;;
    esac
done
