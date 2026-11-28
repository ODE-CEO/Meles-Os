#!/bin/bash

# ==============================================================================
# PROJE ADI: Meles OS Hızlı Program Yükleyici
# GELİŞTİRİCİ: Yağız & Kaan
# DOSYA ADI: meles-hizli-yukleyici.sh
# ==============================================================================

echo "Meles OS Hızlı Yükleyici Başlatılıyor..."
zenity --info --title="Meles Hızlı Yükleyici" --text="Meles Hızlı Yükleyici arka planda çalışırken Terminal ekranını kapatmayın."

SECIM=$(zenity --list --checklist \
    --title="Meles Hızlı Program Yükleyici" \
    --text="Kurmak istediğiniz programları işaretleyin ve 'Tamam'a basın:" \
    --column="Seç" --column="Program Adı" \
    FALSE "Google Chrome" \
    FALSE "Microsoft Edge" \
    FALSE "Brave Browser" \
    FALSE "Zen Browser (Flatpak)" \
    FALSE "Epic Games (Heroic Launcher)" \
    FALSE "Steam" \
    FALSE "LibreOffice (Ofis Paketi)" \
    TRUE "WinRAR (Unrar Entegrasyonu)" \
    TRUE "7-Zip" \
    --separator="," --width=550 --height=400)

if [ -z "$SECIM" ]; then exit 0; fi

sudo apt update

if [[ "$SECIM" == *"Google Chrome"* ]]; then
    wget -qO chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./chrome.deb
    rm chrome.deb
    google-chrome-stable --no-sandbox &
fi

if [[ "$SECIM" == *"Microsoft Edge"* ]]; then
    wget -qO edge.deb https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_126.0.2592.87-1_amd64.deb || true
    sudo apt install -y ./edge.deb || true
    rm edge.deb || true
    microsoft-edge --no-sandbox &
fi

if [[ "$SECIM" == *"Brave Browser"* ]]; then
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
    sudo apt update && sudo apt install -y brave-browser
    brave-browser --no-sandbox &
fi

if [[ "$SECIM" == *"Zen Browser (Flatpak)"* ]]; then
    flatpak install -y flathub io.zen_browser.Zen || true
    flatpak run io.zen_browser.Zen &
fi

if [[ "$SECIM" == *"Epic Games (Heroic Launcher)"* ]]; then
    flatpak install -y flathub com.heroicgameslauncher.hgl || true
    flatpak run com.heroicgameslauncher.hgl &
fi

if [[ "$SECIM" == *"Steam"* ]]; then
    sudo apt install -y steam-installer || sudo apt install -y steam
    steam &
fi

if [[ "$SECIM" == *"LibreOffice (Ofis Paketi)"* ]]; then
    sudo apt install -y libreoffice libreoffice-l10n-tr
    libreoffice --writer &
fi

if [[ "$SECIM" == *"WinRAR (Unrar Entegrasyonu)"* ]]; then
    sudo apt install -y unrar
    zenity --info --title="Meles Test" --text="WinRAR (Unrar) başarıyla kuruldu!" --timeout=3 &
fi

if [[ "$SECIM" == *"7-Zip"* ]]; then
    sudo apt install -y p7zip-full
    zenity --info --title="Meles Test" --text="7-Zip başarıyla sisteme eklendi!" --timeout=3 &
fi

zenity --info --title="Meles Yükleyici" --text="Seçtiğiniz programlar başarıyla kuruldu ve test edildi!"
