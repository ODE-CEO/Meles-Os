#!/bin/bash
# ==============================================================================
# MELES OS: UYGULAMA VE KISAYOL ENJEKTÖRÜ (BÖLÜM 1)
# ==============================================================================

echo ">>> [APP.SH - PART 1] 🚀 Meles Temel Uygulamalar ve Kontrol Merkezi hazırlanıyor..."

# SUDO TUZAĞINI BOZAN DİNAMİK DİZİN TESPİTİ 🎯
if [ -n "$ASIL_DIZIN" ]; then
    KAYNAK_DIZIN="$ASIL_DIZIN"
elif [ -d "$HOME/meles_os_workspace" ]; then
    KAYNAK_DIZIN="$HOME/meles_os_workspace"
else
    KAYNAK_DIZIN="/home/yagiz/meles_os_workspace"
fi

export KAYNAK_DIZIN
export ASIL_DIZIN="$KAYNAK_DIZIN"

HEDEF_BIN="config/includes.chroot/usr/local/bin"
HEDEF_SHARE="config/includes.chroot/usr/local/share"
HEDEF_APPS="config/includes.chroot/usr/share/applications"
HEDEF_AUTOSTART="config/includes.chroot/etc/skel/.config/autostart"
HEDEF_XDG_AUTOSTART="config/includes.chroot/etc/xdg/autostart"
HEDEF_NAUTILUS_SCRIPTS="config/includes.chroot/etc/skel/.local/share/nautilus/scripts"

mkdir -p "$HEDEF_APPS" "$HEDEF_BIN" "$HEDEF_SHARE" "$HEDEF_AUTOSTART" "$HEDEF_XDG_AUTOSTART" "$HEDEF_NAUTILUS_SCRIPTS"

# Sistemin Varsayılan Versiyonunu İşleme 🏷️
mkdir -p config/includes.chroot/etc
echo "26B40" > config/includes.chroot/etc/meles-version

# 1. Meles UI Görünüm Motoru 🎨
mkdir -p "$HEDEF_SHARE/meles_gorunum"
if [ -d "$KAYNAK_DIZIN/meles_gorunum" ]; then
    cp -r "$KAYNAK_DIZIN/meles_gorunum/"* "$HEDEF_SHARE/meles_gorunum/" 2>/dev/null || true
fi

# 2. MELES KARŞILAMA VE ARAÇLAR MERKEZİ (WELCOME SUITE) 🔷🎛️
if [ -d "$KAYNAK_DIZIN/Meles_Karsilama" ]; then
    echo ">>> [APP.SH] 🔷 Meles Karşılama ve Araçlar Merkezi sisteme işleniyor..."
    mkdir -p "$HEDEF_SHARE/meles_karsilama"
    cp -r "$KAYNAK_DIZIN/Meles_Karsilama/"* "$HEDEF_SHARE/meles_karsilama/" 2>/dev/null || true

    # Binary Komut Sarmalayıcıları (/usr/local/bin) ⚡
    cat << 'BIN_EOF' > "$HEDEF_BIN/meles-karsilama"
#!/bin/bash
exec /usr/local/share/meles_karsilama/meles_karsilama.sh "$@"
BIN_EOF

    cat << 'BIN_EOF' > "$HEDEF_BIN/meles-araclar"
#!/bin/bash
exec /usr/local/share/meles_karsilama/meles_araclar.sh "$@"
BIN_EOF

    cat << 'BIN_EOF' > "$HEDEF_BIN/meles-ince-ayar"
#!/bin/bash
exec /usr/local/share/meles_karsilama/meles_ince_ayar.sh "$@"
BIN_EOF

    cat << 'BIN_EOF' > "$HEDEF_BIN/meles-tur"
#!/bin/bash
exec /usr/local/share/meles_karsilama/meles_tur.sh "$@"
BIN_EOF

    cat << 'BIN_EOF' > "$HEDEF_BIN/meles-home"
#!/bin/bash
exec xdg-open "$HOME"
BIN_EOF

    chmod +x "$HEDEF_BIN"/meles-*
    chmod +x "$HEDEF_BIN/meles-home"

    # Başlat Menüsü Kısayolu (ArcMenu Arama İndeksi) 🖥️
    K_WELCOME="$HEDEF_APPS/Meles_Karsilama.desktop"
    cat << DSK_EOF > "$K_WELCOME"
[Desktop Entry]
Name=Meles Karşılama
Comment=Meles OS Başlangıç ve Karşılama Merkezi
Exec=meles-karsilama --show
Icon=preferences-system
Type=Application
Terminal=false
Categories=Settings;System;Utility;
StartupNotify=true
DSK_EOF
    chmod +x "$K_WELCOME"

    # Açılışta Otomatik Başlatma (Autostart) 🚀
    cat << AUTO_EOF > "$HEDEF_AUTOSTART/meles-karsilama.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/meles-karsilama --first-run
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Meles Karşılama
Comment=Meles OS Başlangıç ve Karşılama Ekranı
Icon=preferences-system
AUTO_EOF
    chmod +x "$HEDEF_AUTOSTART/meles-karsilama.desktop"
fi

# 3. Gelişmiş Ayarlar (Kontrol Merkezi & Python Modern Menü) ⚙️
if [ -f "$KAYNAK_DIZIN/gelismis_ayarlar.sh" ]; then
    echo ">>> [APP.SH] ⚙️ Gelişmiş Ayarlar Motoru sisteme işleniyor..."
    cp "$KAYNAK_DIZIN/gelismis_ayarlar.sh" "$HEDEF_BIN/meles-ayarlar"
    chmod +x "$HEDEF_BIN/meles-ayarlar"
fi

if [ -f "$KAYNAK_DIZIN/meles_ayarlar_menu.py" ]; then
    echo ">>> [APP.SH] 🖥️ Gelişmiş Ayarlar Modern GUI sisteme işleniyor..."
    cp "$KAYNAK_DIZIN/meles_ayarlar_menu.py" "$HEDEF_BIN/meles-ayarlar-gui"
    chmod +x "$HEDEF_BIN/meles-ayarlar-gui"
    EXEC_CMD="meles-ayarlar-gui"
else
    EXEC_CMD="meles-ayarlar"
fi

KISAYOL="$HEDEF_APPS/Meles_Gelismis_Ayarlar.desktop"
cat << DSK_EOF > "$KISAYOL"
[Desktop Entry]
Name=Gelişmiş Ayarlar
Comment=Meles OS Sistem ve Görünüm Kontrol Merkezi
Exec=$EXEC_CMD
Icon=preferences-system
Type=Application
Terminal=false
Categories=Settings;System;
StartupNotify=true
DSK_EOF
chmod +x "$KISAYOL"

# 4. GÜNCELLEME MERKEZİ EKLENİYOR 🔄
if [ -f "$KAYNAK_DIZIN/guncelleme_merkezi.sh" ]; then
    echo ">>> [APP.SH] 🔄 Meles Güncelleme Merkezi sisteme ekleniyor..."
    cp "$KAYNAK_DIZIN/guncelleme_merkezi.sh" "$HEDEF_BIN/meles-guncelle"
    chmod +x "$HEDEF_BIN/meles-guncelle"

    K_GUNCELLE="$HEDEF_APPS/Meles_Guncelleme_Merkezi.desktop"
    cat << DSK_EOF > "$K_GUNCELLE"
[Desktop Entry]
Name=Güncelleme Merkezi
Comment=Meles OS Sistem ve Yazılım Güncelleyici
Exec=meles-guncelle
Icon=system-software-update
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DSK_EOF
    chmod +x "$K_GUNCELLE"
fi

# 5. MELES SUITE EKLENİYOR 🧰
if [ -f "$KAYNAK_DIZIN/meles-suite.sh" ]; then
    echo ">>> [APP.SH] 🧰 Meles Suite sisteme ekleniyor..."
    cp "$KAYNAK_DIZIN/meles-suite.sh" "$HEDEF_BIN/meles-suite"
    chmod +x "$HEDEF_BIN/meles-suite"

    K_SUITE="$HEDEF_APPS/Meles_Suite.desktop"
    cat << DSK_EOF > "$K_SUITE"
[Desktop Entry]
Name=Meles Suite
Comment=Meles Yazılım Paketi
Exec=meles-suite
Icon=applications-system
Type=Application
Terminal=false
Categories=Utility;
StartupNotify=true
DSK_EOF
    chmod +x "$K_SUITE"
fi

# 6. MELES APP EKLENİYOR 📱
if [ -f "$KAYNAK_DIZIN/meles_app.sh" ]; then
    echo ">>> [APP.SH] 📱 Meles App sisteme ekleniyor..."
    cp "$KAYNAK_DIZIN/meles_app.sh" "$HEDEF_BIN/meles-app"
    chmod +x "$HEDEF_BIN/meles-app"

    K_APP="$HEDEF_APPS/Meles_App.desktop"
    cat << DSK_EOF > "$K_APP"
[Desktop Entry]
Name=Meles App
Comment=Meles Uygulama Yöneticisi
Exec=meles-app
Icon=application-x-executable
Type=Application
Terminal=false
Categories=Utility;
StartupNotify=true
DSK_EOF
    chmod +x "$K_APP"
fi

# 7. CİHAZ VE BAĞLANTI MERKEZİ EKLENİYOR (Wi-Fi & Bluetooth) 📶🔵
if [ -f "$KAYNAK_DIZIN/cihaz_baglama.sh" ]; then
    echo ">>> [APP.SH] 📶 Meles Cihaz Bağlantı Merkezi sisteme ekleniyor..."
    cp "$KAYNAK_DIZIN/cihaz_baglama.sh" "$HEDEF_BIN/meles-baglanti"
    chmod +x "$HEDEF_BIN/meles-baglanti"

    K_BAGLANTI="$HEDEF_APPS/Meles_Cihaz_Baglanti_Merkezi.desktop"
    cat << DSK_EOF > "$K_BAGLANTI"
[Desktop Entry]
Name=Cihaz Bağlantı Merkezi
Comment=Wi-Fi ve Bluetooth Aygıt Yöneticisi
Exec=meles-baglanti
Icon=network-wireless
Type=Application
Terminal=false
Categories=Network;Settings;
StartupNotify=true
DSK_EOF
    chmod +x "$K_BAGLANTI"
fi

# 8. SİSTEM VE BİLDİRİM BEKÇİSİ (SENTINEL AUTOSTART) 🛡️🔔
if [ -f "$KAYNAK_DIZIN/meles_bekci.sh" ]; then
    echo ">>> [APP.SH] 🛡️ Meles Akıllı Sistem Bekçisi kuruluyor ve açılışa bağlanıyor..."
    cp "$KAYNAK_DIZIN/meles_bekci.sh" "$HEDEF_BIN/meles-bekci"
    chmod +x "$HEDEF_BIN/meles-bekci"

    cat << AUTO_EOF > "$HEDEF_AUTOSTART/meles-bekci.desktop"
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/meles-bekci
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Meles Sistem Bekcisi
Comment=Pil, RAM ve Guncelleme Bildirim Servisi
AUTO_EOF
    chmod +x "$HEDEF_AUTOSTART/meles-bekci.desktop"
fi

# BÖLÜM 2'Yİ ÇAĞIR ⚡
if [ -f "$KAYNAK_DIZIN/app_part2.sh" ]; then
    chmod +x "$KAYNAK_DIZIN/app_part2.sh"
    bash "$KAYNAK_DIZIN/app_part2.sh"
elif [ -f "./app_part2.sh" ]; then
    chmod +x "./app_part2.sh"
    bash "./app_part2.sh"
fi
