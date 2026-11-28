#!/bin/bash

# ==========================================
# MELES OS - ÇOKLU UYGULAMA PAKETİ
# ==========================================

# Renk Kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

clear_screen() {
    clear
}

# ------------------------------------------
# 1. MELES OS RADYO
# ------------------------------------------
meles_radio() {
    while true; do
        clear_screen
        echo -e "${CYAN}==========================================${RESET}"
        echo -e "${BOLD}${PURPLE}       📻 MELES OS RADYO STATION          ${RESET}"
        echo -e "${CYAN}==========================================${RESET}"
        echo -e " [1] Meles FM - Lo-Fi Chill Beats (98.5 MHz)"
        echo -e " [2] Meles Rock - Synthwave Stream (104.2 MHz)"
        echo -e " [3] Meles Retro - 8-Bit Nostalji (88.0 MHz)"
        echo -e " [4] Radyoyu Kapat (Ana Menü)"
        echo -e "${CYAN}------------------------------------------${RESET}"
        read -p "Radyo kanalı seçin [1-4]: " r_choice

        case $r_choice in
            1)
                clear_screen
                echo -e "${GREEN}🎵 Meles FM Yayında! [98.5 MHz]${RESET}"
                echo -e "${YELLOW}Şarkı: Meles Desktop Lofi Beats to Relax/Code to${RESET}"
                echo -e "[||||||||||||||||||||] %100 Ses"
                echo -e "\n(Çalıyor... Ana menüye dönmek için ENTER'a basın)"
                read
                ;;
            2)
                clear_screen
                echo -e "${CYAN}⚡ Meles Rock / Synthwave Yayında! [104.2 MHz]${RESET}"
                echo -e "${YELLOW}Şarkı: Cyber-Meles 2077 Theme${RESET}"
                echo -e "[||||||||||||||||||||] %100 Ses"
                echo -e "\n(Çalıyor... Ana menüye dönmek için ENTER'a basın)"
                read
                ;;
            3)
                clear_screen
                echo -e "${PURPLE}👾 Meles Retro 8-Bit Yayında! [88.0 MHz]${RESET}"
                echo -e "${YELLOW}Şarkı: Chiptune Overclock Adventure${RESET}"
                echo -e "[||||||||||||||||||||] %100 Ses"
                echo -e "\n(Çalıyor... Ana menüye dönmek için ENTER'a basın)"
                read
                ;;
            4)
                break
                ;;
            *)
                echo -e "${RED}Geçersiz seçim!${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------------------
# 2. MELES OS CHATBOT
# ------------------------------------------
meles_chatbot() {
    while true; do
        clear_screen
        echo -e "${GREEN}==========================================${RESET}"
        echo -e "${BOLD}${GREEN}       💬 MELES OS CHATBOT v1.0           ${RESET}"
        echo -e "${GREEN}==========================================${RESET}"
        echo -e "Sadece aşağıdaki tuşları kullanabilirsiniz:\n"
        echo -e " [1] 👋 Selam ver"
        echo -e " [2] ❓ Nasılsın?"
        echo -e " [3] 🚪 Chatbot'tan Çık"
        echo -e "${GREEN}------------------------------------------${RESET}"
        read -p "Tıklamak istediğiniz tuş [1-3]: " c_choice

        case $c_choice in
            1)
                echo -e "\n${BOLD}Sen:${RESET} Selam!"
                sleep 0.4
                echo -e "${CYAN}Meles Bot:${RESET} Aleykümselam! Meles OS sistemine hoş geldin dostum. 🦡"
                echo -e "\nDevam etmek için ENTER'a bas..."
                read
                ;;
            2)
                echo -e "\n${BOLD}Sen:${RESET} Nasılsın?"
                sleep 0.4
                echo -e "${CYAN}Meles Bot:${RESET} Harikayım! Çekirdeğim %100 stabil, RAM kullanımım minimumda. Sen nasılsın? 🚀"
                echo -e "\nDevam etmek için ENTER'a bas..."
                read
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}Lütfen sadece geçerli tuşlara (1 veya 2) basın.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------------------
# 3. MELES ULTRA GELİŞMİŞ AYARLAR
# ------------------------------------------
meles_settings() {
    local rgb_mode="KAPALI"
    local quantum_boost="AÇIK"

    while true; do
        clear_screen
        echo -e "${YELLOW}==========================================${RESET}"
        echo -e "${BOLD}${YELLOW}    ⚙️  MELES ULTRA GELİŞMİŞ AYARLAR       ${RESET}"
        echo -e "${YELLOW}==========================================${RESET}"
        echo -e " [1] Kuantum Çekirdek Hızlandırma : [ $quantum_boost ]"
        echo -e " [2] RGB Terminal Modu            : [ $rgb_mode ]"
        echo -e " [3] Plasebo RAM Temizleyici Çalıştır"
        echo -e " [4] Sistem Isı Sensörleri (Ultra Analiz)"
        echo -e " [5] Ana Menüye Dön"
        echo -e "${YELLOW}------------------------------------------${RESET}"
        read -p "Ayar seçin [1-5]: " s_choice

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
                echo -e "\n${BLUE}[*] Plasebo RAM temizliği başlatılıyor...${RESET}"
                sleep 0.5
                echo -e "${BLUE}[*] Meles Super-Giga-Cleaner çalışıyor...${RESET}"
                sleep 0.8
                echo -e "${GREEN}[✔] Başarılı! 128 GB sanal RAM boşaltıldı (hissedilebilir düzeyde)!${RESET}"
                sleep 1.5
                ;;
            4)
                echo -e "\n${RED}🔥 CPU Sıcaklığı: -273.15 °C (Mutlak Sıfır)${RESET}"
                echo -e "${GREEN}❄️ Soğutma Fanı RPM: 999999 RPM${RESET}"
                echo -e "${PURPLE}⚡ Voltaj Durumu: Aşırı Dengeli${RESET}"
                echo -e "\nDevam etmek için ENTER'a bas..."
                read
                ;;
            5)
                break
                ;;
            *)
                echo -e "${RED}Geçersiz seçenek!${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------------------------
# 4. MELES ÜCRETSİZ OYUN MERKEZİ
# ------------------------------------------
meles_game_center() {
    while true; do
        clear_screen
        echo -e "${RED}==========================================${RESET}"
        echo -e "${BOLD}${RED}     🎮 MELES ÜCRETSİZ OYUN MERKEZİ       ${RESET}"
        echo -e "${RED}==========================================${RESET}"
        echo -e "Meles Store - %100 Ücretsiz Oyun Kataloğu:\n"
        echo -e " [1] CyberMeles 2077: Ultra HD (ÜCRETSİZ)"
        echo -e " [2] Ana Menüye Dön"
        echo -e "${RED}------------------------------------------${RESET}"
        read -p "Oyun seçin [1-2]: " g_choice

        case $g_choice in
            1)
                clear_screen
                echo -e "${YELLOW}[*] 'CyberMeles 2077: Ultra HD' Başlatılıyor...${RESET}"
                sleep 1
                echo -e "${YELLOW}[*] Grafik Motoru (MelesEngine 3D) yükleniyor...${RESET}"
                sleep 1.2
                echo -e "${RED}\n---------------- CRASH REPORT ----------------${RESET}"
                echo -e "${RED}FATAL ERROR: NullPointerInRealityException!${RESET}"
                echo -e "${RED}Direct3D 13.0 failed to initialize on pure Bash core.${RESET}"
                echo -e "${RED}Error Code: 0x00000MELES_BOOM${RESET}"
                echo -e "${RED}Segmentation fault (core dumped)${RESET}"
                echo -e "${RED}----------------------------------------------${RESET}"
                echo -e "\n${PURPLE}(Oyun çöktü. Yapacak bir şey yok, en azından ücretsizdi.)${RESET}"
                echo -e "\nDevam etmek için ENTER'a bas..."
                read
                ;;
            2)
                break
                ;;
            *)
                echo -e "${RED}Geçersiz seçim!${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ==========================================
# ANA MENÜ
# ==========================================
main_menu() {
    while true; do
        clear_screen
        echo -e "${BOLD}${CYAN}==========================================${RESET}"
        echo -e "${BOLD}${CYAN}       🦡 MELES OS UYGULAMA PAKETİ       ${RESET}"
        echo -e "${BOLD}${CYAN}==========================================${RESET}"
        echo -e " [1] 📻 Meles OS Radyo"
        echo -e " [2] 💬 Meles OS Chatbot"
        echo -e " [3] ⚙️ Meles Ultra Gelişmiş Ayarlar"
        echo -e " [4] 🎮 Meles Ücretsiz Oyun Merkezi"
        echo -e " [5] ❌ Çıkış"
        echo -e "${CYAN}==========================================${RESET}"
        read -p "Çalıştırmak istediğiniz uygulamayı seçin [1-5]: " main_choice

        case $main_choice in
            1) meles_radio ;;
            2) meles_chatbot ;;
            3) meles_settings ;;
            4) meles_game_center ;;
            5)
                echo -e "\n${GREEN}Meles OS sisteminden çıkılıyor... Görüşmek üzere! 👋${RESET}\n"
                exit 0
                ;;
            *)
                echo -e "${RED}Geçersiz seçim! Lütfen 1 ile 5 arasında bir sayı girin.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# Scripti Başlat
main_menu
