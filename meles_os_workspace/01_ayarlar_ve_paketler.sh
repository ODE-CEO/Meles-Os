#!/bin/bash
# ------------------------------------------------------------------------------
# MODÜL 1: LIVE-BUILD YAPILANDIRMASI VE PAKET LİSTELERİ (TITANIUM UI EDITION)
# ------------------------------------------------------------------------------
echo ">>> [4/11] lb config ile Debian omurgası inşa ediliyor..."

lb config \
    --distribution bookworm \
    --architecture amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --linux-packages "linux-image" \
    --bootloaders "grub-efi,syslinux" \
    --apt-indices true \
    --apt-secure false \
    --cache true \
    --cache-packages true \
    --cache-stages "bootstrap chroot" \
    --bootappend-live "boot=live components locales=tr_TR.UTF-8 keyboard-layouts=tr quiet splash noprompt hostname=demo live-config.hostname=demo live-config.user-fullname=Meles_Os_Kullanici live-config.username=meles"

echo ">>> Boot ekranı (GRUB/Syslinux) için siyah arka plan tasarlanıyor..."
mkdir -p config/bootloaders/isolinux
mkdir -p config/bootloaders/grub-pc
convert -size 640x480 xc:'#0b1c42' \
    -sparse-color Barycentric '0,0 #081327 0,479 #173a78 639,0 #102958 639,479 #0d1d42' \
    -type TrueColor -depth 8 PNG24:config/bootloaders/isolinux/splash.png
convert -size 1600x900 xc:'#0b1c42' \
    -sparse-color Barycentric '0,0 #081327 0,899 #173a78 1599,0 #102958 1599,899 #0d1d42' \
    -fill '#102653' -draw 'polygon 220,0 390,0 770,900 550,900' \
    -fill '#132d60' -draw 'polygon 790,0 870,0 1260,900 1160,900' \
    -fill '#0b1524' -draw 'rectangle 0,0 1599,8' \
    -fill '#168cff' -draw 'rectangle 0,0 1599,3' \
    -fill '#0b1524' -draw 'rectangle 0,892 1599,899' \
    -fill '#168cff' -draw 'rectangle 0,896 1599,899' \
    -type TrueColor -depth 8 \
    PNG24:config/bootloaders/grub-pc/splash.png

echo ">>> [5/11] Zenginleştirilmiş Paket Listeleri Sisteme Dahil Ediliyor..."
mkdir -p config/package-lists

cat << 'PKGEOF' > config/package-lists/desktop.list.chroot
firefox-esr
synaptic
gnome-system-monitor
zram-tools
earlyoom
power-profiles-daemon
libgtk-3-bin

# --- MASAÜSTÜ, GÖRÜNÜM VE WINDOWS ARAYÜZ MOTORLARI ---
gdm3
gnome-session
gnome-shell
gnome-tweaks
gnome-shell-extension-dash-to-panel
gnome-shell-extension-arc-menu
gnome-shell-extension-appindicator
gnome-shell-extension-desktop-icons-ng
gnome-shell-extension-caffeine
gnome-screenshot
papirus-icon-theme
fonts-noto-core
fonts-inter
fonts-cantarell
fonts-jetbrains-mono
fonts-firacode
fonts-dejavu-core
dconf-cli
uuid-runtime

# --- KIOSK VE X11 GEREKSİNİMLERİ ---
mutter
xinit
xserver-xorg
xserver-xorg-legacy
x11-xserver-utils
dbus-x11

# --- SES VE AĞ YÖNETİMİ ---
pipewire
pipewire-audio-client-libraries
pipewire-pulse
wireplumber
alsa-utils
pavucontrol
bluez
bluez-firmware

# --- EKRAN KARTI VE EVRENSEL AĞ SÜRÜCÜLERİ ---
firmware-amd-graphics
xserver-xorg-video-amdgpu
xserver-xorg-video-nouveau
xserver-xorg-video-intel
firmware-misc-nonfree
firmware-iwlwifi
firmware-realtek

# --- UYGULAMA MAĞAZASI, APPINDICATOR VE FLATPAK DESTEĞİ ---
gnome-software
gnome-software-plugin-flatpak
flatpak
gir1.2-ayatanaappindicator3-0.1

# --- OFİS VE ÜRETKENLİK (LIBREOFFICE) ---
libreoffice
libreoffice-gtk3
libreoffice-l10n-tr

# --- OYUN, WINE VE WINDOWS KÖPRÜSÜ MOTORLARI ---
wine64
winetricks
cabextract
gamemode
libgamemodeauto0
goverlay
mangohud
vkbasalt
mesa-utils
lm-sensors
pciutils
intel-media-va-driver
mesa-vulkan-drivers
vulkan-tools
psmisc
procps
lutris

# --- PYTHON VE MELES MOTORU GEREKSİNİMLERİ ---
python3
python3-pyqt5
python3-psutil
python3-tk
python3-requests
python3-pip
python3-pil
plymouth
plymouth-themes

# --- SİSTEM ARAÇLARI, HIZLI ERİŞİM VE YÖNETİM ---
calamares
calamares-settings-debian
qml-module-qtquick2
qml-module-qtquick-controls2
qml-module-qtquick-layouts
qml-module-qtquick-window2
qml-module-qtgraphicaleffects
zenity
yad
imagemagick
ghostscript
gsettings-desktop-schemas
policykit-1-gnome
wget
curl
unrar
p7zip-full
gnome-terminal
nautilus
gedit
vlc

# --- RAM VE İŞLEMCİ GÜÇ YÖNETİMİ ---
zram-tools
earlyoom
irqbalance
power-profiles-daemon
btop
PKGEOF

# ==============================================================================
# FLATPAK FLATHUB DEPOSUNU DOĞRUDAN SİSTEME GÖMME KANCASI
# ==============================================================================
mkdir -p config/hooks/normal
cat << 'FLATOEF' > config/hooks/normal/06-flathub-setup.hook.chroot
#!/bin/sh
echo "[HOOK-06] Flathub resmi deposu sisteme kalıcı olarak tanıtılıyor..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
FLATOEF
chmod +x config/hooks/normal/06-flathub-setup.hook.chroot
