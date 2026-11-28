#!/bin/bash

# ==================================================
# Meles & Torlis OS Çoklu Araç Scripti (Debian Uyumlu)
# ==================================================

# Renk Tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # Renk Sıfırlama

# --------------------------------------------------
# 1. MODÜL: Meles & Torlis OS Nedir?
# --------------------------------------------------
meles_info() {
    clear
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${YELLOW}${BOLD}        MELES OS & TORLIS OS BİLGİ EKRANI           ${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo ""
    echo -e "${BOLD}Meles OS ve Torlis OS Nedir?${NC}"
    echo -e "${GREEN}• Meles OS & Torlis OS${NC}, yenilikçi mimarilere ve özel kullanıcı"
    echo -e "  deneyimine odaklanan ${YELLOW}yeni nesil bağımsız işletim sistemleridir.${NC}"
    echo ""
    echo -e "${BOLD}Sistem Özellikleri ve Durumu:${NC}"
    echo -e "  ${CYAN}[1]${NC} ${BOLD}Sistem Mimarisi:${NC} Hafif sistem kaynak kullanımı ve modüler yapı."
    echo -e "  ${CYAN}[2]${NC} ${BOLD}Görsel Arayüz:${NC} Özelleştirilebilir dinamik masaüstü ve mobil ortamı."
    echo -e "  ${CYAN}[3]${NC} ${BOLD}Durum:${NC} Aktif geliştirme aşamasında olan yeni projelerdir."
    echo ""
    echo -e "${CYAN}----------------------------------------------------${NC}"
    read -p "Ana menüye dönmek için Enter'a basın..." dummy
}

# --------------------------------------------------
# 2. MODÜL: Meles OS Matrix Kod Simülasyonu
# --------------------------------------------------
meles_matrix() {
    clear
    echo -e "${GREEN}Meles OS Matrix Simülasyonu Başlatılıyor...${NC}"
    echo -e "${YELLOW}(Çıkmak için Ctrl+C tuşlarına basın)${NC}"
    sleep 1.5

    # Eğer sistemde cmatrix paketi varsa onu çalıştırır
    if command -v cmatrix &> /dev/null; then
        cmatrix -C green -b -u 2
    else
        # Yerel Bash Fallback Simülasyonu (cmatrix yoksa çalışır)
        trap 'echo -e "${NC}"; clear; return' INT

        lines=$(tput lines 2>/dev/null || echo 24)
        cols=$(tput cols 2>/dev/null || echo 80)

        words=("MELES_OS" "TORLIS" "KERNEL_INIT" "SYSTEM_READY" "010101" "BOOT_OK" "MELES_CORE")

        while true; do
            rand_col=$((RANDOM % cols))
            rand_word=${words[$RANDOM % ${#words[@]}]}

            tput cup $((RANDOM % lines)) $rand_col 2>/dev/null

            if [ $((RANDOM % 4)) -eq 0 ]; then
                echo -ne "${BOLD}${YELLOW}$rand_word${NC}${GREEN}"
            else
                echo -n $((RANDOM % 2))
            fi
            sleep 0.02
        done
    fi
}

# --------------------------------------------------
# 3. MODÜL: Meles Albüm
# --------------------------------------------------
meles_album() {
    ALBUM_DIR="./meles_album_photos"

    # Eğer klasör varsa ve içinde resim varsa gerçek fotoğrafları gösterir
    if [ -d "$ALBUM_DIR" ] && [ "$(ls -A "$ALBUM_DIR" 2>/dev/null)" ]; then
        clear
        echo -e "${BLUE}=== MELES ALBÜM (Görsel Klasörü) ===${NC}\n"

        if command -v chafa &> /dev/null; then
            for img in "$ALBUM_DIR"/*; do
                clear
                chafa "$img"
                echo -e "${YELLOW}Görsel: $(basename "$img")${NC}"
                echo -e "${CYAN}-----------------------------------${NC}"
                read -p "Sonraki görsel için Enter (Çıkış için 'q'): " nav
                [[ "$nav" == "q" ]] && break
            done
        else
            echo -e "${GREEN}Sistem görüntüleyicisi ile açılıyor...${NC}"
            xdg-open "$ALBUM_DIR" &> /dev/null &
            read -p "Enter'a basarak menüye dönebilirsiniz..." dummy
        fi
    else
        # Klasör/Resim yoksa ASCII Sanat/Konsept Galeri gösterimi
        idx=1
        while true; do
            clear
            echo -e "${BLUE}====================================================${NC}"
            echo -e "${BOLD}${YELLOW}             MELES OS ALBÜM & KONSEPT GALLERY       ${NC}"
            echo -e "${BLUE}====================================================${NC}"
            echo ""

            case $idx in
                1)
                    echo -e "${YELLOW}[Görsel 1/3] Meles OS Logo Konsepti:${NC}\n"
                    echo -e "${GREEN}"
                    echo "        /\_/\   "
                    echo "       ( o.o )  MELES OS v1.0"
                    echo "        > ^ <   Bağımsız İşletim Sistemi"
                    echo -e "${NC}"
                    ;;
                2)
                    echo -e "${YELLOW}[Görsel 2/3] Torlis OS Arayüz Konsepti:${NC}\n"
                    echo -e "${CYAN}"
                    echo "  +---------------------------------------+  "
                    echo "  | [Meles Menu]        12:00 PM   [Wifi] |  "
                    echo "  +---------------------------------------+  "
                    echo "  |  [Terminal]    [Files]    [Browser]   |  "
                    echo "  |                                       |  "
                    echo "  +---------------------------------------+  "
                    echo -e "${NC}"
                    ;;
                3)
                    echo -e "${YELLOW}[Görsel 3/3] Çekirdek (Kernel) Mimarisi:${NC}\n"
                    echo -e "${BLUE}"
                    echo "   [ User Space / Uygulamalar ]"
                    echo "               │"
                    echo "   [ Torlis / Meles System Services ]"
                    echo "               │"
                    echo "   [ Linux / Custom Microkernel ]"
                    echo -e "${NC}"
                    ;;
            esac

            echo -e "${CYAN}----------------------------------------------------${NC}"
            echo -e "İpucu: Kendi fotoğraflarını yüklemek için script ile aynı dizinde"
            echo -e "'${YELLOW}meles_album_photos${NC}' klasörü oluşturup içine resim atabilirsin."
            echo ""
            echo "1) Sonraki Görsel"
            echo "2) Önceki Görsel"
            echo "0) Ana Menüye Dön"
            read -p "Seçiminiz: " alb_choice

            case $alb_choice in
                1) idx=$(( (idx % 3) + 1 )) ;;
                2) idx=$(( idx == 1 ? 3 : idx - 1 )) ;;
                0) break ;;
            esac
        done
    fi
}

# --------------------------------------------------
# 4. MODÜL: Meles OS Radyo
# --------------------------------------------------
meles_radio() {
    while true; do
        clear
        echo -e "${CYAN}====================================================${NC}"
        echo -e "${BOLD}${PURPLE}       📻 MELES OS RADYO İSTASYONU                 ${NC}"
        echo -e "${CYAN}====================================================${NC}"
        echo -e "  ${YELLOW}[1]${NC} Meles FM - Lo-Fi Chill Beats (98.5 MHz)"
        echo -e "  ${YELLOW}[2]${NC} Meles Rock - Synthwave Stream (104.2 MHz)"
        echo -e "  ${YELLOW}[3]${NC} Meles Retro - 8-Bit Nostalji (88.0 MHz)"
        echo -e "  ${YELLOW}[0]${NC} Ana Menüye Dön"
        echo -e "${CYAN}----------------------------------------------------${NC}"
        read -p "Radyo kanalı seçin [0-3]: " r_choice

        case $r_choice in
            1)
                clear
                echo -e "${GREEN}🎵 Meles FM Yayında! [98.5 MHz]${NC}"
                echo -e "${YELLOW}Şarkı: Meles Desktop Lofi Beats to Relax/Code to${NC}"
                echo -e "[||||||||||||||||||||] %100 Ses"
                echo -e "\n(Çalıyor... Ana menüye dönmek için Enter'a basın)"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}⚡ Meles Rock / Synthwave Yayında! [104.2 MHz]${NC}"
                echo -e "${YELLOW}Şarkı: Cyber-Meles 2077 Theme${NC}"
                echo -e "[||||||||||||||||||||] %100 Ses"
                echo -e "\n(Çalıyor... Ana menüye dönmek için Enter'a basın)"
                read
                ;;
            3)
                clear
                echo -e "${PURPLE}👾 Meles Retro 8-Bit Yayında! [88.0 MHz]${NC}"
                echo -e "${YELLOW}Şarkı: Chiptune Overclock Adventure${NC}"
                echo -e "[||||||||||||||||||||] %100 Ses"
                echo -e "\n(Çalıyor... Ana menüye dönmek için Enter'a basın)"
                read
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Geçersiz seçim!${NC}"
                sleep 1
                ;;
        esac
    done
}

# --------------------------------------------------
# 5. MODÜL: Meles OS Chatbot
# --------------------------------------------------
meles_chatbot() {
    while true; do
        clear
        echo -e "${GREEN}====================================================${NC}"
        echo -e "${BOLD}${GREEN}       💬 MELES OS CHATBOT v1.0                     ${NC}"
        echo -e "${GREEN}====================================================${NC}"
        echo -e "Sadece aşağıdaki tuşları kullanabilirsiniz:\n"
        echo -e "  ${YELLOW}[1]${NC} 👋 Selam ver"
        echo -e "  ${YELLOW}[2]${NC} ❓ Nasılsın?"
        echo -e "  ${YELLOW}[0]${NC} Ana Menüye Dön"
        echo -e "${GREEN}----------------------------------------------------${NC}"
        read -p "Tıklamak istediğiniz tuş [0-2]: " c_choice

        case $c_choice in
            1)
                echo -e "\n${BOLD}Sen:${NC} Selam!"
                sleep 0.4
                echo -e "${CYAN}Meles Bot:${NC} Aleykümselam! Meles OS sistemine hoş geldin dostum. 🦡"
                echo -e "\nDevam etmek için Enter'a bas..."
                read
                ;;
            2)
                echo -e "\n${BOLD}Sen:${NC} Nasılsın?"
                sleep 0.4
                echo -e "${CYAN}Meles Bot:${NC} Harikayım! Çekirdeğim %100 stabil, RAM kullanımım minimumda. Sen nasılsın? 🚀"
                echo -e "\nDevam etmek için Enter'a bas..."
                read
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Lütfen sadece geçerli tuşlara (1 veya 2) basın.${NC}"
                sleep 1
                ;;
        esac
    done
}

# --------------------------------------------------
# 6. MODÜL: Meles Ultra Gelişmiş Ayarlar
# --------------------------------------------------
meles_settings() {
    local rgb_mode="KAPALI"
    local quantum_boost="AÇIK"

    while true; do
        clear
        echo -e "${YELLOW}====================================================${NC}"
        echo -e "${BOLD}${YELLOW}    ⚙️  MELES ULTRA GELİŞMİŞ AYARLAR                 ${NC}"
        echo -e "${YELLOW}====================================================${NC}"
        echo -e "  ${CYAN}[1]${NC} Kuantum Çekirdek Hızlandırma : [ $quantum_boost ]"
        echo -e "  ${CYAN}[2]${NC} RGB Terminal Modu            : [ $rgb_mode ]"
        echo -e "  ${CYAN}[3]${NC} Plasebo RAM Temizleyici Çalıştır"
        echo -e "  ${CYAN}[4]${NC} Sistem Isı Sensörleri (Ultra Analiz)"
        echo -e "  ${CYAN}[0]${NC} Ana Menüye Dön"
        echo -e "${YELLOW}----------------------------------------------------${NC}"
        read -p "Ayar seçin [0-4]: " s_choice

        case $s_choice in
            1)
                if [ "$quantum_boost" == "AÇIK" ]; then
                    quantum_boost="KAPALI"
                else
                    quantum_boost="AÇIK"
                fi
                ;;
            2)
                if [ "$rgb_mode" == "KAPALI" ]; then
                    rgb_mode="AÇIK"
                else
                    rgb_mode="KAPALI"
                fi
                ;;
            3)
                echo -e "\n${BLUE}[*] Plasebo RAM temizliği başlatılıyor...${NC}"
                sleep 0.5
                echo -e "${BLUE}[*] Meles Super-Giga-Cleaner çalışıyor...${NC}"
                sleep 0.8
                echo -e "${GREEN}[✔] Başarılı! 128 GB sanal RAM boşaltıldı!${NC}"
                sleep 1.5
                ;;
            4)
                echo -e "\n${RED}🔥 CPU Sıcaklığı: -273.15 °C (Mutlak Sıfır)${NC}"
                echo -e "${GREEN}❄️ Soğutma Fanı RPM: 999999 RPM${NC}"
                echo -e "${PURPLE}⚡ Voltaj Durumu: Aşırı Dengeli${NC}"
                echo -e "\nDevam etmek için Enter'a bas..."
                read
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Geçersiz seçenek!${NC}"
                sleep 1
                ;;
        esac
    done
}

# --------------------------------------------------
# 7. MODÜL: Meles Ücretsiz Oyun Merkezi
# --------------------------------------------------
meles_game_center() {
    while true; do
        clear
        echo -e "${RED}====================================================${NC}"
        echo -e "${BOLD}${RED}     🎮 MELES ÜCRETSİZ OYUN MERKEZİ                 ${NC}"
        echo -e "${RED}====================================================${NC}"
        echo -e "Meles Store - %100 Ücretsiz Oyun Kataloğu:\n"
        echo -e "  ${YELLOW}[1]${NC} CyberMeles 2077: Ultra HD (ÜCRETSİZ)"
        echo -e "  ${YELLOW}[0]${NC} Ana Menüye Dön"
        echo -e "${RED}----------------------------------------------------${NC}"
        read -p "Oyun seçin [0-1]: " g_choice

        case $g_choice in
            1)
                clear
                echo -e "${YELLOW}[*] 'CyberMeles 2077: Ultra HD' Başlatılıyor...${NC}"
                sleep 1
                echo -e "${YELLOW}[*] Grafik Motoru (MelesEngine 3D) yükleniyor...${NC}"
                sleep 1.2
                echo -e "${RED}\n---------------- CRASH REPORT ----------------${NC}"
                echo -e "${RED}FATAL ERROR: NullPointerInRealityException!${NC}"
                echo -e "${RED}Direct3D 13.0 failed to initialize on pure Bash core.${NC}"
                echo -e "${RED}Error Code: 0x00000MELES_BOOM${NC}"
                echo -e "${RED}Segmentation fault (core dumped)${NC}"
                echo -e "${RED}----------------------------------------------${NC}"
                echo -e "\n${PURPLE}(Oyun çöktü. Yapacak bir şey yok, en azından ücretsizdi.)${NC}"
                echo -e "\nDevam etmek için Enter'a bas..."
                read
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Geçersiz seçim!${NC}"
                sleep 1
                ;;
        esac
    done
}

# --------------------------------------------------
# ANA MENÜ
# --------------------------------------------------
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}====================================================${NC}"
        echo -e "${BOLD}${CYAN}            MELES & TORLIS OS KONTROL PANELİ        ${NC}"
        echo -e "${GREEN}====================================================${NC}"
        echo -e "  ${YELLOW}1)${NC} Meles & Torlis OS Nedir? (Bilgi Ekranı)"
        echo -e "  ${YELLOW}2)${NC} Meles OS Matrix Ekranı (Akan Kod Simülasyonu)"
        echo -e "  ${YELLOW}3)${NC} Meles OS Albüm"
        echo -e "  ${YELLOW}4)${NC} 📻 Meles OS Radyo"
        echo -e "  ${YELLOW}5)${NC} 💬 Meles OS Chatbot (Selam/Nasılsın)"
        echo -e "  ${YELLOW}6)${NC} ⚙️ Meles Ultra Gelişmiş Ayarlar"
        echo -e "  ${YELLOW}7)${NC} 🎮 Meles Ücretsiz Oyun Merkezi"
        echo -e "  ${YELLOW}0)${NC} Çıkış"
        echo -e "${GREEN}====================================================${NC}"
        read -p "Lütfen bir seçenek girin [0-7]: " choice

        case $choice in
            1) meles_info ;;
            2) meles_matrix ;;
            3) meles_album ;;
            4) meles_radio ;;
            5) meles_chatbot ;;
            6) meles_settings ;;
            7) meles_game_center ;;
            0)
                echo -e "\n${GREEN}Meles OS sisteminden çıkış yapıldı.${NC}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Geçersiz seçenek! Tekrar deneyin.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Çalıştır
main_menu
