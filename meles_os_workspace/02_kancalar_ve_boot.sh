#!/bin/bash
# ------------------------------------------------------------------------------
# MODÜL 2: SİSTEM KANCALARI, BOOT ANİMASYONU VE GRUB/ISOLINUX HACKLERİ
# ------------------------------------------------------------------------------
echo ">>> [6/11] Sistem kancaları (Hooks) oluşturuluyor..."
mkdir -p config/hooks/normal

# Kanca 1: Wine Multiarch 32-bit Desteği ve Oyun Sürücüleri
cat << 'HOOKEOF' > config/hooks/normal/00-multiarch-wine-gaming.hook.chroot
#!/bin/sh
dpkg --add-architecture i386
apt-get update -qq || true
apt-get install -y wine32:i386 libvulkan1:i386 mesa-vulkan-drivers:i386 libglx-mesa0:i386 libgl1-mesa-dri:i386 || true
HOOKEOF
chmod +x config/hooks/normal/00-multiarch-wine-gaming.hook.chroot

# Kanca 2: Wayland'i Kapatıp X11 Zorlama
cat << 'HOOKEOF' > config/hooks/normal/01-disable-wayland.hook.chroot
#!/bin/sh
sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/daemon.conf
HOOKEOF
chmod +x config/hooks/normal/01-disable-wayland.hook.chroot

# Otomatik oturum açma: kurulu Meles hesabı ilk oturumda şifre istemeden açılır.
cat << 'HOOKEOF' > config/hooks/normal/01-enable-autologin.hook.chroot
#!/bin/sh
CONF=/etc/gdm3/custom.conf
mkdir -p /etc/gdm3
touch "$CONF"
sed -i '/^AutomaticLoginEnable=/d; /^AutomaticLogin=/d' "$CONF"
if grep -q '^\[daemon\]' "$CONF"; then
    sed -i '/^\[daemon\]/a AutomaticLoginEnable=true\nAutomaticLogin=meles' "$CONF"
else
    cat >> "$CONF" << 'GDM_EOF'
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=meles
GDM_EOF
fi
HOOKEOF
chmod +x config/hooks/normal/01-enable-autologin.hook.chroot

# Kanca 3: PipeWire Otomatik Başlatma
cat << 'HOOKEOF' > config/hooks/normal/02-enable-pipewire.hook.chroot
#!/bin/sh
systemctl --global enable pipewire.socket
systemctl --global enable pipewire-pulse.socket
systemctl --global enable wireplumber.service
HOOKEOF
chmod +x config/hooks/normal/02-enable-pipewire.hook.chroot

# Kanca 4: Plymouth Font Ve Çevre Hazırlığı
cat << 'HOOKEOF' > config/hooks/normal/03-configure-plymouth-env.hook.chroot
#!/bin/sh
apt-get update -qq || true
apt-get install -y fonts-dejavu-core plymouth-label || true
mkdir -p /usr/share/plymouth/themes/meles
HOOKEOF
chmod +x config/hooks/normal/03-configure-plymouth-env.hook.chroot

# Kanca 5: Plymouth (Siyah-Beyaz Boot Ekranı)
cat << 'HOOKEOF' > config/hooks/normal/04-setup-plymouth.hook.chroot
#!/bin/sh
plymouth-set-default-theme meles
update-initramfs -u -k all || true
HOOKEOF
chmod +x config/hooks/normal/04-setup-plymouth.hook.chroot

# Kanca 6: Calamares Paket Adımını Koru
cat << 'HOOKEOF' > config/hooks/normal/05-fix-calamares-purge.hook.chroot
#!/bin/sh
if [ -f /etc/calamares/modules/packages.conf ]; then
    cat > /etc/calamares/modules/packages.conf << 'PACKAGES_EOF'
backend: apt
operations:
  - try_remove:
    - live-boot
    - live-config
    - live-config-systemd
    - live-tools
PACKAGES_EOF
fi
HOOKEOF
chmod +x config/hooks/normal/05-fix-calamares-purge.hook.chroot

# Kanca 7: Global Oyun Çevre Değişkenleri
cat << 'HOOKEOF' > config/hooks/normal/07-gaming-env-vars.hook.chroot
#!/bin/sh
echo "export MESA_GL_THREAD=true" >> /etc/environment
echo "export RADV_PERFTEST=aco" >> /etc/environment
HOOKEOF
chmod +x config/hooks/normal/07-gaming-env-vars.hook.chroot

# ==============================================================================
# SYSTEMD ACİL MOD TANILAMA EKRANI (GERÇEK KERNEL PANIC'İ DEĞİL)
# ==============================================================================
mkdir -p config/includes.chroot/usr/local/sbin
mkdir -p config/includes.chroot/etc/systemd/system/emergency.target.d
cp "$ASIL_DIZIN/meles-bsod.sh" config/includes.chroot/usr/local/sbin/meles-bsod.sh
chmod 0755 config/includes.chroot/usr/local/sbin/meles-bsod.sh

cat << 'BSOD_SERVICE_EOF' > config/includes.chroot/etc/systemd/system/meles-bsod.service
[Unit]
Description=Meles OS boot failure diagnostics
After=systemd-journald.service
Before=emergency.service
ConditionPathExists=/usr/local/sbin/meles-bsod.sh

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/meles-bsod.sh
StandardInput=tty
StandardOutput=tty
StandardError=tty
TTYPath=/dev/tty1
TTYReset=yes
TimeoutStartSec=40
BSOD_SERVICE_EOF

cat << 'BSOD_TARGET_EOF' > config/includes.chroot/etc/systemd/system/emergency.target.d/meles-bsod.conf
[Unit]
Wants=meles-bsod.service
BSOD_TARGET_EOF

# ==============================================================================
# KIOSK KURULUM MODU (BİRLEŞMİŞ KURULUM KÖPRÜSÜ AKTİF)
# ==============================================================================
mkdir -p config/includes.chroot/etc/systemd/system
mkdir -p config/includes.chroot/usr/local/bin

cat << 'SYSEOF' > config/includes.chroot/etc/systemd/system/meles-kiosk.service
[Unit]
Description=Meles OS Tam Ekran Kiosk Kurulum Modu
After=systemd-user-sessions.service plymouth-quit-wait.service getty@tty2.service
Conflicts=getty@tty2.service
ConditionKernelCommandLine=meles_mode=install

[Service]
User=root
Environment=DISPLAY=:0
ExecStart=/usr/bin/xinit /usr/local/bin/meles-kiosk.sh -- :0 vt2
Type=idle
StandardInput=tty
StandardOutput=tty
TTYPath=/dev/tty2

[Install]
WantedBy=multi-user.target
SYSEOF

cat << 'SH_EOF' > config/includes.chroot/usr/local/bin/meles-kiosk.sh
#!/bin/bash
export DISPLAY=:0
export QT_QPA_PLATFORM=xcb
export GTK_THEME="Adwaita-dark"
export QT_STYLE_OVERRIDE="Fusion"
xsetroot -solid "#0f172a" -cursor_name left_ptr

dbus-run-session mutter --sm-disable &
MUTTER_PID=$!
sleep 2

if [ -x /usr/local/bin/meleskurulum.sh ]; then
    /usr/local/bin/meleskurulum.sh
else
    echo "Calamares başlatıcısı bulunamadı." >&2
    exit 1
fi

kill $MUTTER_PID 2>/dev/null || true

echo "Kurulum arayüzü kapandı."
sleep 3
exit 0
SH_EOF
chmod +x config/includes.chroot/usr/local/bin/meles-kiosk.sh

cat << 'INSTALL_UI_EOF' > config/includes.chroot/usr/local/bin/meles-install-ui.sh
#!/bin/bash
if ! grep -qw 'boot=live' /proc/cmdline; then
    exit 0
fi

# Install-mode boots use the dedicated kiosk service, not a second desktop
# autostart instance of Calamares.
if grep -qw 'meles_mode=install' /proc/cmdline; then
    exit 0
fi

if [ ! -e /run/live/medium ] && [ ! -e /lib/live/mount/medium ]; then
    exit 0
fi
exec /usr/local/bin/meleskurulum.sh
INSTALL_UI_EOF
chmod +x config/includes.chroot/usr/local/bin/meles-install-ui.sh

# Use one live-session installer entry point; disable the legacy duplicate launchers.
mkdir -p config/includes.chroot/etc/xdg/autostart
cat << 'AUTOSTART_EOF' > config/includes.chroot/etc/xdg/autostart/meles-kurulum-live.desktop
[Desktop Entry]
Type=Application
Name=Meles OS Kurulumu
Comment=Calamares kurulum programını doğrudan başlat
Exec=/usr/local/bin/meles-install-ui.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
StartupNotify=true
AUTOSTART_EOF

for eski_baslatici in meles-kurulum.desktop meles-auto-install.desktop; do
    cat > "config/includes.chroot/etc/xdg/autostart/$eski_baslatici" << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Hidden=true
NoDisplay=true
AUTOSTART_EOF
done

cat << 'HOOKEOF' > config/hooks/normal/08-enable-kiosk.hook.chroot
#!/bin/sh
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config
echo "needs_root_rights=yes" >> /etc/X11/Xwrapper.config
systemctl enable meles-kiosk.service
HOOKEOF
chmod +x config/hooks/normal/08-enable-kiosk.hook.chroot

# ==============================================================================
# GNOME Animasyonları, Koyu Tema ve Şeffaflık (Blur) Kilidi
# ==============================================================================
mkdir -p config/includes.chroot/usr/share/glib-2.0/schemas
cat << 'GSCHEMAEOF' > config/includes.chroot/usr/share/glib-2.0/schemas/98-meles-animations.gschema.override
[org.gnome.desktop.interface]
enable-animations=true
color-scheme='prefer-dark'
gtk-theme='Adwaita-dark'

[org.gnome.mutter]
edge-tiling=true
attach-modal-dialogs=true
center-new-windows=true

[org.gnome.shell.extensions.blur-my-shell]
sigma=30
brightness=0.60
color=rgba(0, 0, 0, 0.40)
noise-amount=0.00
noise-lightness=0.00
hacks-level=1
blur-dash=true
blur-overview=true
blur-panel=true
blur-lockscreen=true

[org.gnome.shell.extensions.blur-my-shell.appfolder]
blur=true

[org.gnome.shell.extensions.blur-my-shell.panel]
blur=true
GSCHEMAEOF

cat << 'HOOKEOF' > config/hooks/normal/06-compile-animations.hook.chroot
#!/bin/sh
glib-compile-schemas /usr/share/glib-2.0/schemas/
HOOKEOF
chmod +x config/hooks/normal/06-compile-animations.hook.chroot

echo ">>> [7/11] Özel uygulamalar ve Boot animasyonu enjekte ediliyor..."
mkdir -p config/includes.chroot/usr/share/plymouth/themes/meles

if [ -f "$ASIL_DIZIN/meleslogo.png" ]; then
    convert "$ASIL_DIZIN/meleslogo.png" -colorspace Gray \
        "config/includes.chroot/usr/share/plymouth/themes/meles/meleslogo.png"
fi

THEME_DIR="config/includes.chroot/usr/share/plymouth/themes/meles"
for frame in $(seq 0 11); do
    angle=$((frame * 30))
    convert "$THEME_DIR/meleslogo.png" \
        -fill '#f5f8ff' -colorize 100 \
        -resize 112x112 \
        -background none -gravity center -extent 128x128 \
        -rotate "$angle" \
        -background none -gravity center -extent 128x128 \
        "$THEME_DIR/meles-frame-$frame.png"
done
convert -size 620x18 xc:'#11151d' \
    -stroke '#e8eef8' -strokewidth 1 -fill none \
    -draw 'roundrectangle 0,0 619,17 8,8' \
    "$THEME_DIR/progress-track.png"
convert -size 600x8 xc:black \
    -sparse-color Barycentric '0,0 #168cff 599,0 #f4f7ff' \
    "$THEME_DIR/progress-fill.png"

cat << 'PLYMOUTHEOF' > config/includes.chroot/usr/share/plymouth/themes/meles/meles.plymouth
[Plymouth Theme]
Name=Meles OS Boot
Description=Siyah arka plan, animasyonlu M logosu ve ilerleme cubugu
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/meles
ScriptFile=/usr/share/plymouth/themes/meles/meles.script
PLYMOUTHEOF

cat << 'SCRIPTEOF' > config/includes.chroot/usr/share/plymouth/themes/meles/meles.script
Window.SetBackgroundTopColor(0, 0, 0);
Window.SetBackgroundBottomColor(0, 0, 0);

screen_width = Window.GetWidth();
screen_height = Window.GetHeight();
frame_count = 12;
for (i = 0; i < frame_count; i++)
    logo_frames[i] = Image("meles-frame-" + i + ".png");

logo_sprite = Sprite(logo_frames[0]);
logo_x = screen_width / 2 - logo_frames[0].GetWidth() / 2;
logo_y = screen_height / 2 - 130;
logo_sprite.SetPosition(logo_x, logo_y, 10);

brand_image = Image.Text("MELES OS", 0.96, 0.98, 1);
brand_sprite = Sprite(brand_image);
brand_sprite.SetPosition(screen_width / 2 - brand_image.GetWidth() / 2,
                         logo_y + logo_frames[0].GetHeight() + 16, 10);

message_sprite = Sprite();
percent_sprite = Sprite();
track_image = Image("progress-track.png");
track_sprite = Sprite(track_image);
track_x = screen_width / 2 - track_image.GetWidth() / 2;
track_y = screen_height / 2 + 72;
track_sprite.SetPosition(track_x, track_y, 5);
fill_source = Image("progress-fill.png");
fill_sprite = Sprite();
fill_sprite.SetPosition(track_x + 9, track_y + 5, 6);

mode = Plymouth.GetMode();
base_text = "Bilgisayar Baslatiliyor";
if (mode == "shutdown") { base_text = "Bilgisayar Kapatiliyor"; }
else if (mode == "reboot") { base_text = "Yeniden Baslatiliyor"; }
else if (mode == "suspend") { base_text = "Uyku Moduna Geciliyor"; }
frame_counter = 0;
last_progress_width = -1;
boot_progress = 0;
fun progress_callback (duration, progress) {
    boot_progress = progress;
}
Plymouth.SetBootProgressFunction(progress_callback);

fun refresh_callback () {
    frame_counter++;
    t = frame_counter / 50.0;
    frame_index = Math.Int(t * 12) % frame_count;
    logo_sprite.SetImage(logo_frames[frame_index]);
    dots_count = Math.Int(t * 2) % 4;
    dots = "";
    if (dots_count == 1) { dots = "."; }
    else if (dots_count == 2) { dots = ".."; }
    else if (dots_count == 3) { dots = "..."; }
    msg_image = Image.Text(base_text + dots, 1, 1, 1);
    message_sprite.SetImage(msg_image);
    message_sprite.SetPosition(screen_width / 2 - msg_image.GetWidth() / 2,
                               track_y - 34, 10);
    progress = boot_progress;
    if (progress < 0) { progress = 0; }
    if (progress > 1) { progress = 1; }
    pct = Math.Int(progress * 100);
    pct_text = "%" + pct;
    pct_image = Image.Text(pct_text, 0.76, 0.83, 0.91);
    percent_sprite.SetImage(pct_image);
    percent_sprite.SetPosition(screen_width / 2 - pct_image.GetWidth() / 2,
                               track_y + 25, 10);
    progress_width = Math.Int(fill_source.GetWidth() * progress);
    if (progress_width > 0 && progress_width != last_progress_width) {
        fill_sprite.SetImage(fill_source.Scale(progress_width, fill_source.GetHeight()));
        last_progress_width = progress_width;
    }
}
Plymouth.SetRefreshFunction(refresh_callback);
SCRIPTEOF

# ==============================================================================
# GİZLİ EASTER EGG: GÜVENLİ MOD + Y/N/M PROTOKOLÜ (FLAPPY BIRD YAMASI)
# ==============================================================================
echo ">>> [HOOK] Gizli Ayarlar ve Güvenli Mod Y/N/M Protokolü Ekleniyor..."
cat << 'HOOKEOF' > config/hooks/normal/13-meles-secret.hook.chroot
#!/bin/sh
cat << 'SECRETEOF' > /usr/local/bin/meles-secret.sh
#!/bin/bash
export TERM=linux
exec < /dev/tty1 > /dev/tty1 2>&1

if command -v plymouth &> /dev/null; then
    plymouth quit
fi

clear
echo -e "\n\e[36m[ Meles System ]\e[0m Guvenli Mod Baslangici\n"
echo -ne "\e[33mGerçekten güvenli modda başlatmak istiyormusunuz? y/n: \e[0m"
IFS= read -r -n 1 key
echo ""

if [[ "$key" == "y" || "$key" == "Y" ]]; then
    echo -e "\e[32m[+] Guvenli mod baslatiliyor...\e[0m"
    sleep 1
    clear
    exit 0
elif [[ "$key" == "n" || "$key" == "N" ]]; then
    echo -e "\e[31m[-] Iptal edildi. Boot menusune donuluyor...\e[0m"
    sleep 1
    systemctl reboot -ff
elif [[ "$key" == "m" || "$key" == "M" ]]; then
    echo -e "\e[35m[!] Ozel protokol devrede...\e[0m"
    sleep 1
else
    echo -e "\e[33mGecersiz secim yapildi. Guvenli modla devam ediliyor...\e[0m"
    sleep 1
    clear
    exit 0
fi

play_flappy() {
    local w=40 h=15 bx=10 by=8 px=40 py=8 score=0 vel=0
    local old_tty=$(stty -g)
    stty -echo -icanon min 0 time 0
    tput civis
    
    clear
    echo -e "\n\e[33mOyun basliyor...\e[0m"
    for i in 3 2 1; do
        echo -ne "\r\e[32m$i...\e[0m "
        sleep 1
    done
    echo -e "\n\e[31mBASLA!\e[0m"
    sleep 0.5
    
    while true; do
        IFS= read -r -t 0.1 -n 1 input
        if [[ "$input" == $'\e' ]]; then break; fi
        if [[ "$input" == " " || "$input" == "w" || "$input" == "W" ]]; then vel=-2; fi
        
        by=$((by + vel))
        vel=$((vel + 1))
        px=$((px - 2))
        
        if [ $px -le 0 ]; then
            px=$w
            py=$((RANDOM % 7 + 4))
            score=$((score + 1))
        fi
        
        if [ $by -le 0 ] || [ $by -ge $h ]; then break; fi
        if [ $px -le $bx ] && [ $((px + 3)) -ge $bx ]; then
            if [ $by -lt $((py - 3)) ] || [ $by -gt $((py + 3)) ]; then break; fi
        fi
        
        local buffer="\e[H\n\e[36m Meles OS Failsafe\e[0m | \e[32mSkor: $score\e[0m | [Zipla: BOSLUK | Cikis: ESC]\n\n"
        for ((y=1; y<=h; y++)); do
            local line="  "
            for ((x=1; x<=w; x++)); do
                if [ $x -eq $bx ] && [ $y -eq $by ]; then
                    line+="\e[33m@\e[0m"
                elif [ $x -ge $px ] && [ $x -le $((px + 3)) ] && { [ $y -le $((py - 3)) ] || [ $y -ge $((py + 3)) ]; }; then
                    line+="\e[32m|\e[0m"
                else
                    line+=" "
                fi
            done
            buffer+="$line\n"
        done
        echo -ne "$buffer"
    done
    
    stty "$old_tty"
    tput cnorm
    clear
    echo -e "\n\e[31m   --- OYUN BITTI ---\e[0m\n"
    echo "   Skorun: $score"
    echo -e "\n   Devam etmek icin bir tusa basin..."
    IFS= read -r -n 1 -s
}

while true; do
    clear
    echo -e "\e[31m=========================================\e[0m"
    echo -e "\e[31m          GIZLI AYARLAR MENUSU           \e[0m"
    echo -e "\e[31m=========================================\e[0m"
    echo ""
    echo " 1) Baslatmaya Geri Don (Sistemi Ac)"
    echo " 2) Boot Menusune Geri Don (Yeniden Baslat)"
    echo " 3) Guvenli Modu 'Guvenli' Modda Ac"
    echo ""
    read -p " Seciminiz [1-3]: " secim

    case $secim in
        1) clear; exit 0 ;;
        2) clear; systemctl reboot -ff ;;
        3) play_flappy ;;
    esac
done
SECRETEOF
chmod +x /usr/local/bin/meles-secret.sh

cat << 'SYSEOF' > /etc/systemd/system/meles-secret.service
[Unit]
Description=Meles Secret Easter Egg
DefaultDependencies=no
After=sysinit.target local-fs.target
Before=basic.target
ConditionKernelCommandLine=meles_secret=1

[Service]
Type=oneshot
ExecStartPre=-/bin/plymouth quit
ExecStart=/usr/local/bin/meles-secret.sh
StandardInput=tty-force
StandardOutput=tty
TTYPath=/dev/tty1
TimeoutSec=0

[Install]
WantedBy=multi-user.target
SYSEOF
systemctl enable meles-secret.service
HOOKEOF
chmod +x config/hooks/normal/13-meles-secret.hook.chroot

# ==============================================================================
# BOOT MENÜSÜ HACK (UEFI VE LEGACY İÇİN DÜZELTME VE GİZLİ TETİKLEYİCİ)
# ==============================================================================
echo ">>> [HOOK] Orijinal Boot Menüsü Meles seçenekleriyle değiştiriliyor..."
mkdir -p config/hooks/live
cat << 'HOOKEOF' > config/hooks/live/99-meles-bootmenu.hook.binary
#!/bin/sh
if [ -d binary/boot/grub ] && [ -f config/bootloaders/grub-pc/grub.cfg ]; then
    cp config/bootloaders/grub-pc/grub.cfg binary/boot/grub/grub.cfg
    mkdir -p binary/boot/grub/meles
    cp config/bootloaders/grub-pc/theme.txt binary/boot/grub/meles/theme.txt
    cp config/bootloaders/grub-pc/splash.png binary/boot/grub/meles/splash.png
    cp config/bootloaders/grub-pc/selected.png binary/boot/grub/meles/selected.png
    cp config/bootloaders/grub-pc/meles-title.pf2 binary/boot/grub/meles/meles-title.pf2
    cp config/bootloaders/grub-pc/meles-menu.pf2 binary/boot/grub/meles/meles-menu.pf2
fi

if [ -d binary/isolinux ] && [ -f config/bootloaders/isolinux/menu.cfg ]; then
    cp config/bootloaders/isolinux/menu.cfg binary/isolinux/menu.cfg
    cp config/bootloaders/isolinux/splash.png binary/isolinux/splash.png
fi
HOOKEOF
chmod +x config/hooks/live/99-meles-bootmenu.hook.binary
