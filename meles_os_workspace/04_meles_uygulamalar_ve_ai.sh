#!/bin/bash
# ==============================================================================
# MODÜL 4: MELES AI, KISAYOLLAR VE SÜRÜCÜ KURUCU (BAŞLAT MENÜSÜ İNDEKSLEMESİ)
# ==============================================================================

set -e
echo "========================================================================"
echo ">>> [MODÜL 4] MELES ÖZEL UYGULAMALARI VE MODERN ARAÇLAR EKLENİYOR..."
echo "========================================================================"

mkdir -p config/includes.chroot/etc/xdg/autostart
mkdir -p config/includes.chroot/usr/local/bin
mkdir -p config/includes.chroot/etc/skel/Masaüstü
mkdir -p config/includes.chroot/etc/skel/Desktop
mkdir -p config/includes.chroot/usr/share/applications

# ==============================================================================
# ŞİFRESİZ SUDO
# ==============================================================================
mkdir -p config/includes.chroot/etc/sudoers.d
rm -f config/includes.chroot/etc/sudoers.d/meles-nopasswd 2>/dev/null || true
echo "ALL ALL=(ALL) NOPASSWD: /usr/local/bin/meleskurulum.sh" > config/includes.chroot/etc/sudoers.d/meles-nopasswd
echo "ALL ALL=(ALL) NOPASSWD: /usr/local/bin/meles-hizli-yukleyici.sh" >> config/includes.chroot/etc/sudoers.d/meles-nopasswd
chmod 0440 config/includes.chroot/etc/sudoers.d/meles-nopasswd

KAYNAK_DIZIN="${ASIL_DIZIN:-$(pwd)}"
if [ -f "$KAYNAK_DIZIN/meles-hizli-yukleyici.sh" ]; then
    cp "$KAYNAK_DIZIN/meles-hizli-yukleyici.sh" config/includes.chroot/usr/local/bin/meles-hizli-yukleyici.sh
else
    echo "Hızlı paket kurucu kaynağı bulunamadı: meles-hizli-yukleyici.sh" >&2
    exit 1
fi
chmod +x config/includes.chroot/usr/local/bin/meles-hizli-yukleyici.sh

for ARAc in meles_glass_center.py meles-sistem-araci.sh meles_merkez.py meles-sistem-onarim.py; do
    if [ ! -f "$KAYNAK_DIZIN/$ARAc" ]; then
        echo "Meles Kontrol Merkezi kaynağı bulunamadı: $ARAc" >&2
        exit 1
    fi
    cp "$KAYNAK_DIZIN/$ARAc" "config/includes.chroot/usr/local/bin/$ARAc"
    chmod 0755 "config/includes.chroot/usr/local/bin/$ARAc"
done

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Firefox.desktop
[Desktop Entry]
Name=Firefox
Comment=Web tarayıcısı
Exec=firefox-esr %u
Icon=firefox-esr
Type=Application
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
DESKTOPEOF
rm -f config/includes.chroot/usr/share/applications/Meles_Browser.desktop
rm -f config/includes.chroot/usr/local/bin/melesbrowser.py

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_OS_Kur.desktop
[Desktop Entry]
Name=Meles OS'i Kur
Comment=Meles OS'i bilgisayarınıza kalıcı olarak kurun
Exec=env GTK_THEME=Adwaita-dark QT_STYLE_OVERRIDE=Fusion /usr/local/bin/meleskurulum.sh
Icon=system-software-install
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Hizli_Yukleyici.desktop
[Desktop Entry]
Name=Meles Hızlı Yükleyici
Comment=Yazılım paketlerini hızlıca kurun
Exec=/usr/local/bin/meles-hizli-yukleyici.sh
Icon=system-software-install
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Surucu_Kurucu.desktop
[Desktop Entry]
Name=Meles Sürücü Kurucu
Comment=Donanımı algılayıp uygun sürücüleri kurun
Exec=python3 /usr/local/bin/meles_glass_center.py
Icon=preferences-system
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Kontrol_Merkezi.desktop
[Desktop Entry]
Name=Meles Kontrol Merkezi
Comment=Cam görünümlü donanım ve kaynak yönetimi
Exec=python3 /usr/local/bin/meles_glass_center.py
Icon=preferences-system
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Merkez.desktop
[Desktop Entry]
Name=Meles Merkez
Comment=Meles uygulamalarını tek yerden açın
Exec=python3 /usr/local/bin/meles_merkez.py
Icon=applications-system
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Tasking.desktop
[Desktop Entry]
Name=Meles Görev Yöneticisi
Comment=Sistem Kaynaklarını İzle
Exec=gnome-system-monitor
Icon=utilities-system-monitor
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Ekran_Alintisi.desktop
[Desktop Entry]
Name=Hızlı Ekran Alıntısı
Comment=Ekranın bir bölümünü veya tamamını kaydet
Exec=gnome-screenshot --interactive
Icon=camera-photo
Type=Application
Terminal=false
Categories=Utility;Graphics;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Terminal_Modu.desktop
[Desktop Entry]
Name=Saf Terminal (Arayüzü Kapat)
Comment=RAM'i boşaltmak için tüm masaüstünü kapatır
Exec=gnome-terminal -- bash -c "echo 'Masaüstü öldürülüyor... Geri dönmek için siyah ekrana masaustu-ac yazın.'; sleep 3; sudo systemctl isolate multi-user.target"
Icon=utilities-terminal
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Paket_Yukleyici.desktop
[Desktop Entry]
Name=Meles Paket Yükleyici
Comment=Uygulamaları depolardan kurun ve kaldırın
Exec=synaptic-pkexec
Icon=system-software-install
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cat << 'DESKTOPEOF' > config/includes.chroot/usr/share/applications/Meles_Sistem_Onarim.desktop
[Desktop Entry]
Name=Meles Sistem Onarımı
Comment=Paket, önyükleme ve sürücü tanılaması
Exec=python3 /usr/local/bin/meles-sistem-onarim.py
Icon=preferences-system
Type=Application
Terminal=false
Categories=System;
StartupNotify=true
DESKTOPEOF

cp "$KAYNAK_DIZIN/meles-sistem-onarim.sh" \
    config/includes.chroot/usr/local/bin/meles-sistem-onarim.sh
chmod 0755 config/includes.chroot/usr/local/bin/meles-sistem-onarim.sh

for desktop in \
    Meles_AI.desktop Meles_Browser.desktop Meles_Ekran_Alintisi.desktop \
    Meles_Hizli_Yukleyici.desktop Meles_Kontrol_Merkezi.desktop \
    Meles_OS_Kur.desktop Meles_Surucu_Kurucu.desktop Meles_Tasking.desktop \
    Meles_Terminal_Modu.desktop Meles_Sistem_Onarim.desktop \
    Meles_Paket_Yukleyici.desktop
do
    rm -f "config/includes.chroot/etc/skel/Desktop/$desktop"
    rm -f "config/includes.chroot/etc/skel/Masaüstü/$desktop"
done

for desktop_dir in config/includes.chroot/etc/skel/Desktop config/includes.chroot/etc/skel/Masaüstü; do
    mkdir -p "$desktop_dir"
    cp config/includes.chroot/usr/share/applications/Meles_Merkez.desktop "$desktop_dir/Meles_Merkez.desktop"
    cat > "$desktop_dir/Kisisel_Klasor.desktop" << 'HOME_DESKTOP_EOF'
[Desktop Entry]
Name=Kişisel Klasör
Comment=Kullanıcı dosyalarınızı açın
Exec=/usr/local/bin/meles-home
Icon=folder-home
Type=Application
Terminal=false
Categories=Utility;
StartupNotify=true
HOME_DESKTOP_EOF
    chmod 0755 "$desktop_dir/Meles_Merkez.desktop" "$desktop_dir/Kisisel_Klasor.desktop"
done

cat << 'TRUSTEOF' > config/includes.chroot/etc/xdg/autostart/meles-trust.desktop
[Desktop Entry]
Type=Application
Name=Trust Meles Icons
Exec=bash -c "sleep 5; for f in ~/Masaüstü/*.desktop ~/Desktop/*.desktop; do if [ -f \"\$f\" ]; then chmod +x \"\$f\"; gio set \"\$f\" metadata::trusted true; fi; done; rm -f ~/Desktop/debian-installer-launcher.desktop ~/Masaüstü/debian-installer-launcher.desktop 2>/dev/null || true;"
Hidden=false
NoDisplay=true
X-GNOME-Autostart-Phase=Desktop
X-GNOME-Autostart-enabled=true
TRUSTEOF

# ==============================================================================
# EKRAN KARTI SÜRÜCÜ KURUCU
# ==============================================================================
cat << 'DRVSCRIPTEOF' > config/includes.chroot/usr/local/bin/meles-surucu-kur.sh
#!/bin/bash
exec python3 /usr/local/bin/meles_glass_center.py "$@"
DRVSCRIPTEOF
chmod +x config/includes.chroot/usr/local/bin/meles-surucu-kur.sh

echo ">>> [MODÜL 4] BAŞARIYLA TAMAMLANDI!"
