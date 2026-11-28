#!/bin/bash
# ==============================================================================
# MODÜL 3: TITANIUM DEVRİM SÜRÜMÜ (SAF ADWAITA, ARCMENU, DASH-TO-PANEL)
# ==============================================================================

set -e
echo "========================================================================"
echo ">>> [MODÜL 3] TITANIUM ARAYÜZ VE SİSTEM YAPILANDIRMASI BAŞLIYOR..."
echo "========================================================================"

# ÇALIŞMA ALANI DİNAMİK TESPİTİ (SUDO KORUMASI)
if [ -n "$ASIL_DIZIN" ]; then
    WORKSPACE_DIR="$ASIL_DIZIN"
elif [ -d "$HOME/meles_os_workspace" ]; then
    WORKSPACE_DIR="$HOME/meles_os_workspace"
elif [ -d "/home/yagiz/meles_os_workspace" ]; then
    WORKSPACE_DIR="/home/yagiz/meles_os_workspace"
else
    WORKSPACE_DIR="$(pwd)"
fi
export WORKSPACE_DIR

mkdir -p config/hooks/normal
mkdir -p config/includes.chroot/usr/local/bin
mkdir -p config/includes.chroot/usr/local/share/meles_gorunum
mkdir -p config/includes.chroot/etc/skel/Masaüstü
mkdir -p config/includes.chroot/etc/skel/Desktop
mkdir -p config/includes.chroot/etc/skel/.config/autostart
mkdir -p config/includes.chroot/etc/skel/.config/gtk-3.0
mkdir -p config/includes.chroot/etc/skel/.config/gtk-4.0
mkdir -p config/includes.chroot/etc/gtk-3.0
mkdir -p config/includes.chroot/etc/gtk-4.0
mkdir -p config/includes.chroot/etc/xdg/autostart
mkdir -p config/includes.chroot/usr/share/icons
mkdir -p config/includes.chroot/usr/share/glib-2.0/schemas
mkdir -p config/includes.chroot/etc/dconf/profile
mkdir -p config/includes.chroot/etc/dconf/db/local.d
mkdir -p config/includes.chroot/usr/share/backgrounds/meles
mkdir -p config/includes.chroot/usr/share/gnome-background-properties
mkdir -p config/includes.chroot/usr/share/gnome-shell/extensions/meles-notifications@melesos
mkdir -p config/includes.chroot/usr/share/gnome-shell/extensions/meles-resource-glass@melesos
mkdir -p config/includes.chroot/usr/share/gnome-shell/theme

# ==============================================================================
# SAĞ ALTTAN ANİMASYONLU BİLDİRİM MOTORU (GNOME EXTENSION)
# ==============================================================================
cat << 'NOTIF_META' > config/includes.chroot/usr/share/gnome-shell/extensions/meles-notifications@melesos/metadata.json
{
  "name": "Meles Notification Position",
  "description": "Bildirimleri animasyonlu olarak sağ alta yerleştirir",
  "uuid": "meles-notifications@melesos",
  "shell-version": ["43", "43.9", "44"]
}
NOTIF_META

cat << 'NOTIF_JS' > config/includes.chroot/usr/share/gnome-shell/extensions/meles-notifications@melesos/extension.js
const Clutter = imports.gi.Clutter;
const Main = imports.ui.main;

class Extension {
    enable() {
        if (Main.messageTray && Main.messageTray._bannerBin) {
            Main.messageTray._bannerBin.y_align = Clutter.ActorAlign.END;
            Main.messageTray._bannerBin.x_align = Clutter.ActorAlign.END;
            Main.messageTray.bannerAlignment = Clutter.ActorAlign.END;
            Main.messageTray._bannerBin.margin_bottom = 44;
            Main.messageTray._bannerBin.margin_right = 16;
        }
    }
    disable() {
        if (Main.messageTray && Main.messageTray._bannerBin) {
            Main.messageTray._bannerBin.y_align = Clutter.ActorAlign.START;
            Main.messageTray._bannerBin.x_align = Clutter.ActorAlign.CENTER;
            Main.messageTray.bannerAlignment = Clutter.ActorAlign.CENTER;
            Main.messageTray._bannerBin.margin_bottom = 0;
            Main.messageTray._bannerBin.margin_right = 0;
        }
    }
}

function init() {
    return new Extension();
}
NOTIF_JS

# ==============================================================================
# SAĞ ÜST LİQUID GLASS SAAT VE CPU/RAM GÖSTERGESİ
# ==============================================================================
cat << 'RESOURCE_META' > config/includes.chroot/usr/share/gnome-shell/extensions/meles-resource-glass@melesos/metadata.json
{
  "name": "Meles Resource Glass",
  "description": "Sağ üstte Liquid Glass saat ve CPU/RAM göstergesi",
  "uuid": "meles-resource-glass@melesos",
  "shell-version": ["43", "44"]
}
RESOURCE_META

cat << 'RESOURCE_JS' > config/includes.chroot/usr/share/gnome-shell/extensions/meles-resource-glass@melesos/extension.js
const GLib = imports.gi.GLib;
const St = imports.gi.St;
const Main = imports.ui.main;
const ByteArray = imports.byteArray;

class MelesResourceGlass {
    enable() {
        this._lastCpu = null;
        this._refreshCount = 0;
        this._topMemoryProcess = "ölçülüyor";
        this._topCpuProcess = "ölçülüyor";
        this._root = new St.BoxLayout({
            style: "spacing: 12px; padding: 3px 10px; margin: 3px 7px; " +
                "border-radius: 12px; border: 1px solid rgba(255,255,255,0.28); " +
                "background-color: rgba(18,22,29,0.72);",
            y_align: St.Align.MIDDLE
        });
        this._root.add_style_class_name("meles-resource-glass");
        this._clock = new St.Label({
            text: "--:--",
            y_align: St.Align.MIDDLE,
            style: "color: #ffffff; font-weight: 700;"
        });
        this._resources = new St.Label({
            text: "CPU --%  ·  RAM --",
            y_align: St.Align.MIDDLE,
            style: "color: rgba(235,242,250,0.88); font-size: 11px;"
        });
        this._root.add_child(this._clock);
        this._root.add_child(this._resources);
        Main.layoutManager.addTopChrome(this._root, { trackFullscreen: true });
        this._focusChangedId = global.display.connect(
            "notify::focus-window",
            () => this._updateVisibility()
        );
        this._monitorChangedId = Main.layoutManager.connect(
            "monitors-changed",
            () => this._position()
        );
        this._refresh();
        this._timer = GLib.timeout_add_seconds(
            GLib.PRIORITY_LOW,
            5,
            () => {
                this._refresh();
                return GLib.SOURCE_CONTINUE;
            }
        );
    }

    _position() {
        let monitor = Main.layoutManager.primaryMonitor;
        if (!monitor || !this._root) {
            return;
        }
        let [, width] = this._root.get_preferred_width(-1);
        this._root.set_position(
            Math.max(monitor.x + 8, monitor.x + monitor.width - width - 16),
            monitor.y + 10
        );
    }

    _updateVisibility() {
        if (this._root) {
            this._root.visible = !global.display.focus_window && !Main.overview.visible;
        }
    }

    _updateTopProcesses() {
        let [success, output, error, status] =
            GLib.spawn_command_line_sync("ps -eo comm=,rss=,%cpu= --sort=-rss");
        if (!success || status !== 0) {
            let detail = ByteArray.toString(error).trim();
            logError(new Error(detail || `ps exited with status ${status}`),
                "Unable to identify the largest resource consumers");
            this._topMemoryProcess = "ölçüm kullanılamıyor";
            this._topCpuProcess = "ölçüm kullanılamıyor";
            return;
        }

        for (let line of ByteArray.toString(output).split("\n")) {
            let match = line.trim().match(/^(.*?)\s+(\d+)\s+([\d.]+)$/);
            if (match) {
                this._topMemoryProcess =
                    `${match[1]} ${(Number(match[2]) / 1024).toFixed(0)} MB`;
                break;
            }
        }

        let [cpuSuccess, cpuOutput, cpuError, cpuStatus] =
            GLib.spawn_command_line_sync("ps -eo comm=,%cpu= --sort=-%cpu");
        if (!cpuSuccess || cpuStatus !== 0) {
            let detail = ByteArray.toString(cpuError).trim();
            logError(new Error(detail || `ps exited with status ${cpuStatus}`),
                "Unable to identify the highest CPU consumer");
            this._topCpuProcess = "ölçüm kullanılamıyor";
            return;
        }

        for (let line of ByteArray.toString(cpuOutput).split("\n")) {
            let match = line.trim().match(/^(.*?)\s+([\d.]+)$/);
            if (match) {
                this._topCpuProcess = `${match[1]} ${match[2]}%`;
                return;
            }
        }
        this._topCpuProcess = "süreç bulunamadı";
    }

    _read(path) {
        try {
            let [ok, bytes] = GLib.file_get_contents(path);
            return ok ? ByteArray.toString(bytes) : "";
        } catch (error) {
            if (!this._readErrorLogged) {
                logError(error, "Unable to read system resource information");
                this._readErrorLogged = true;
            }
            return "";
        }
    }

    _refresh() {
        this._refreshCount++;
        let now = GLib.DateTime.new_now_local();
        this._clock.text = now.format("%H:%M  ·  %d.%m");

        let stat = this._read("/proc/stat").split("\n")[0].trim().split(/\s+/);
        let cpu = "--";
        if (stat.length >= 5 && stat[0] === "cpu") {
            let values = stat.slice(1).map(Number);
            let idle = values[3] + (values[4] || 0);
            let total = values.slice(0, 8).reduce((sum, value) => sum + value, 0);
            if (this._lastCpu) {
                let totalDelta = total - this._lastCpu.total;
                let idleDelta = idle - this._lastCpu.idle;
                if (totalDelta > 0) {
                    cpu = Math.round(100 * (1 - idleDelta / totalDelta));
                }
            }
            this._lastCpu = { total, idle };
        }

        let memory = this._read("/proc/meminfo");
        let totalMatch = memory.match(/^MemTotal:\s+(\d+)/m);
        let availableMatch = memory.match(/^MemAvailable:\s+(\d+)/m);
        let ram = "--";
        if (totalMatch && availableMatch) {
            let total = Number(totalMatch[1]);
            let used = total - Number(availableMatch[1]);
            ram = `${(used / 1024).toFixed(0)} / ${(total / 1024).toFixed(0)} MB`;
        }
        if (this._refreshCount % 12 === 1) {
            this._updateTopProcesses();
        }
        this._resources.text = `CPU ${cpu}%  ·  RAM ${ram}`;
        this._root.set_tooltip_text(
            `En çok RAM: ${this._topMemoryProcess}\nEn çok CPU: ${this._topCpuProcess}`
        );
        this._position();
        this._updateVisibility();
    }

    disable() {
        if (this._timer) {
            GLib.Source.remove(this._timer);
            this._timer = null;
        }
        if (this._monitorChangedId) {
            Main.layoutManager.disconnect(this._monitorChangedId);
            this._monitorChangedId = null;
        }
        if (this._focusChangedId) {
            global.display.disconnect(this._focusChangedId);
            this._focusChangedId = null;
        }
        if (this._root) {
            Main.layoutManager.removeChrome(this._root);
            this._root = null;
        }
    }
}

function init() {
    return new MelesResourceGlass();
}
RESOURCE_JS

# Do not launch the legacy XFCE panel alongside GNOME; it performs package
# installation during login and duplicates desktop services in the background.
cat << 'UI_DISABLED_EOF' > config/includes.chroot/etc/xdg/autostart/meles-ui.desktop
[Desktop Entry]
Type=Application
Name=Meles UI Engine
Comment=Legacy XFCE panel launcher (disabled for GNOME sessions)
Hidden=true
NoDisplay=true
X-GNOME-Autostart-enabled=false
UI_DISABLED_EOF
cp config/includes.chroot/etc/xdg/autostart/meles-ui.desktop \
    config/includes.chroot/etc/skel/.config/autostart/meles-ui.desktop

# ==============================================================================
# TITANIUM ARAYÜZ MOTORLARI (PAKET KURULUM KANCASI - ÖNCELİK 08)
# ==============================================================================
cat << 'HOOKEOF' > config/hooks/normal/08-install-ui-deps.hook.chroot
#!/bin/sh
echo "[HOOK] Titanium Arayüz Motoru (Dash-to-Panel, ArcMenu & Temalar) Gömülüyor..."
apt-get update -qq || true
apt-get install -y gnome-shell-extension-dash-to-panel gnome-shell-extension-arc-menu gnome-shell-extension-appindicator gnome-shell-extension-caffeine gnome-themes-extra yad jq wmctrl xdotool network-manager-gnome dconf-cli unzip wget fonts-inter fonts-jetbrains-mono || true

# Mutter Metacity Siyah Tema Uyumluluk Köprüsü
mkdir -p /usr/share/themes/Adwaita-dark
if [ -d /usr/share/themes/Adwaita/metacity-1 ]; then
    ln -sf /usr/share/themes/Adwaita/metacity-1 /usr/share/themes/Adwaita-dark/metacity-1
fi
HOOKEOF
chmod +x config/hooks/normal/08-install-ui-deps.hook.chroot

# ==============================================================================
# RAM OPTİMİZASYONU
# ==============================================================================
cat << 'HOOKEOF' > config/hooks/normal/09-ram-optimization.hook.chroot
#!/bin/sh
echo "[HOOK] RAM optimizasyonlari devrede (Tracker ve Software servisleri öldürülüyor)..."
systemctl --global mask tracker-extract-3.service tracker-miner-fs-3.service tracker-writeback-3.service evolution-source-registry.service evolution-calendar-factory.service || true
mkdir -p /etc/xdg/autostart
echo -e "[Desktop Entry]\nHidden=true" > /etc/xdg/autostart/gnome-software-service.desktop
cat > /etc/default/zramswap << 'ZRAM_EOF'
ALGO=lz4
PERCENT=25
PRIORITY=100
ZRAM_EOF
cat > /etc/default/earlyoom << 'EARLYOOM_EOF'
EARLYOOM_ARGS="-r 3600 -m 5 -s 10"
EARLYOOM_EOF
systemctl enable zramswap.service earlyoom.service
HOOKEOF
chmod +x config/hooks/normal/09-ram-optimization.hook.chroot

# ==============================================================================
# MÜHÜR 1: ARCMENU (PANELİN EN SOLUNDAKİ TEK 'M' LOGOSU)
# ==============================================================================
cat << 'GSCHEMAEOF' > config/includes.chroot/usr/share/glib-2.0/schemas/97-meles-arcmenu.gschema.override
[org.gnome.shell.extensions.arcmenu]
menu-layout='Windows'
menu-button-icon='Custom_Icon'
custom-menu-button-icon='/usr/share/icons/meleslogo.png'
custom-menu-button-icon-size=24.0
arc-menu-placement='DTP'
hotkey-open-menu=true
menu-hotkey='Super_L'
enable-fallback-menu-hotkey=true
menu-theme='Dark'
enable-menu-theme=true
search-entry-position='Top'
show-search-button=true
show-frequent-apps=true
show-pinned-apps=true
multi-monitor=true
distro-icon=0
GSCHEMAEOF

# ==============================================================================
# MÜHÜR 2: DASH-TO-PANEL DÜZENİ (KARE BUTONLAR KAPALI - SADECE 'M' LOGOSU)
# ==============================================================================
cat << 'GSCHEMAEOF' > config/includes.chroot/usr/share/glib-2.0/schemas/98-meles-dash-to-panel.gschema.override
[org.gnome.shell.extensions.dash-to-panel]
panel-position='BOTTOM'
panel-size=30
multi-monitors=true
all-monitors=true
appicon-margin=2
appicon-padding=4
tray-padding=6
dot-position='BOTTOM'
trans-use-custom-bg=true
trans-bg-color='#000000'
trans-use-custom-opacity=true
trans-panel-opacity=1.0
show-apps-icon-visible=false
show-activities-button=false
animate-appicon-hover=true
show-showdesktop-hover=true
isolate-workspaces=false
hide-overview-on-startup=true
GSCHEMAEOF

# ==============================================================================
# MÜHÜR 3: SİSTEM KÖKÜ (SAF KOYU TEMA, JETBRAINS MONO & MUTTER SİYAH BAŞLIK)
# ==============================================================================
cat << 'GSCHEMAEOF' > config/includes.chroot/usr/share/glib-2.0/schemas/99-meles-os.gschema.override
[org.gnome.shell]
disable-user-extensions=false
enabled-extensions=['dash-to-panel@jderose9.github.com', 'arcmenu@arcmenu.com', 'appindicatorsupport@rgcjonas.gmail.com', 'caffeine@patapon.info', 'meles-notifications@melesos', 'ding@rastersoft.com']
favorite-apps=['org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop', 'firefox-esr.desktop']

[org.gnome.desktop.background]
picture-uri='file:///usr/share/backgrounds/meles/arkaplan5.png'
picture-uri-dark='file:///usr/share/backgrounds/meles/arkaplan5.png'
primary-color='#000000'
color-shading-type='solid'

[org.gnome.desktop.interface]
gtk-theme='Adwaita-dark'
color-scheme='prefer-dark'
icon-theme='Papirus-Dark'
cursor-theme='Adwaita'
enable-animations=true
clock-format='24h'
clock-show-seconds=true
clock-show-date=true
clock-show-weekday=true
font-name='Inter 11'
document-font-name='Inter 11'
monospace-font-name='JetBrains Mono 11'

[org.gnome.mutter]
edge-tiling=true
attach-modal-dialogs=true
center-new-windows=true
dynamic-workspaces=true
overlay-key=''

[org.gnome.desktop.wm.preferences]
theme='Adwaita'
button-layout='appmenu:minimize,maximize,close'
titlebar-font='Inter Bold 11'

[org.gnome.shell.extensions.ding]
show-home=true
show-trash=true
show-volumes=false
show-network-volumes=false
icon-size='standard'

[org.gnome.Terminal.ProfilesList]
default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'
list=['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']

[org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9/]
visible-name='Meles Titanium'
use-theme-colors=false
background-color='#000000'
foreground-color='#38bdf8'
use-system-font=false
font='JetBrains Mono 11'
cell-width-scale=1.0
cell-height-scale=1.0

[org.gnome.settings-daemon.plugins.power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='suspend'
GSCHEMAEOF

# ==============================================================================
# TAM DİKDÖRTGEN VE ZİFİRİ SİYAH BAŞLIK ÇUBUĞU MOTORU (SİSTEM GENELİ & SKEL)
# ==============================================================================
cat << 'GTKEOF' > config/includes.chroot/etc/skel/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-font-name=Inter 11
GTKEOF

cat << 'GTKEOF' > config/includes.chroot/etc/skel/.config/gtk-4.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Papirus-Dark
gtk-cursor-theme-name=Adwaita
gtk-font-name=Inter 11
GTKEOF

cp config/includes.chroot/etc/skel/.config/gtk-3.0/settings.ini config/includes.chroot/etc/gtk-3.0/settings.ini
cp config/includes.chroot/etc/skel/.config/gtk-4.0/settings.ini config/includes.chroot/etc/gtk-4.0/settings.ini

# ==============================================================================
# TITANIUM ULTRA-KARE CSS MOTORU (0PX RADICAL ENFORCER)
# ==============================================================================
cat << 'CSSEOF' > config/includes.chroot/etc/skel/.config/gtk-3.0/gtk.css
/* 1. TÜM WIDGET'LARIN KÖŞELERİNİ TAM KARE YAP (0PX) */
* {
    border-radius: 0px !important;
    -gtk-outline-radius: 0px !important;
}

/* 2. PENCERELER, ÇERÇEVELER, DİYALOGLAR VE GÖLGELER */
window,
.window-frame,
decoration,
decoration-overlay,
window.csd,
window.ssd,
dialog,
messagedialog {
    border-radius: 0px !important;
    box-shadow: none !important;
    margin: 0px !important;
}

/* 3. TÜM BAŞLIK ÇUBUKLARI ZİFİRİ SİYAH (#000000) */
headerbar,
.titlebar,
window.csd headerbar,
window.ssd headerbar.titlebar,
window.ssd .titlebar,
.default-decoration,
headerbar.default-decoration,
window.ssd decoration {
    background: #000000 !important;
    background-color: #000000 !important;
    background-image: none !important;
    color: #ffffff !important;
    border-radius: 0px !important;
    border-bottom: 1px solid #1e293b !important;
    box-shadow: none !important;
}

headerbar:backdrop,
.titlebar:backdrop,
window.csd headerbar:backdrop,
window.ssd headerbar.titlebar:backdrop,
window.ssd .titlebar:backdrop {
    background: #000000 !important;
    background-color: #000000 !important;
    background-image: none !important;
    color: #94a3b8 !important;
    border-radius: 0px !important;
    border-bottom: 1px solid #1e293b !important;
}

headerbar .title,
.titlebar .title,
window.ssd headerbar.titlebar .title {
    color: #ffffff !important;
    font-weight: bold !important;
}

/* 4. BAŞLIK ÇUBUĞU BUTONLARI (KAPAT, KÜÇÜLT, BÜYÜT) */
headerbar button,
.titlebar button,
window.ssd headerbar.titlebar button,
windowcontrols button {
    background: transparent !important;
    background-color: transparent !important;
    background-image: none !important;
    color: #ffffff !important;
    border-radius: 0px !important;
    border: none !important;
    box-shadow: none !important;
    padding: 4px 8px !important;
    min-height: 24px !important;
    min-width: 24px !important;
}

headerbar button:hover,
.titlebar button:hover,
windowcontrols button:hover {
    background-color: #1e293b !important;
    color: #38bdf8 !important;
}

headerbar button.close:hover,
.titlebar button.close:hover,
windowcontrols button.close:hover {
    background-color: #e11d48 !important;
    color: #ffffff !important;
}

/* 5. TÜM BUTONLAR, GİRİŞ KUTULARI VE ARAYÜZ ELEMANLARI (0PX) */
button,
entry,
spinbutton,
combobox,
combobox button,
search-entry,
switch,
switch slider,
scale,
scale slider,
scale trough,
progressbar,
progressbar progress,
levelbar block,
scrollbar slider {
    border-radius: 0px !important;
    box-shadow: none !important;
}

/* 6. LİBADWAİTA KARTLARI, LİSTELER VE SEKMELER */
.card,
.boxed-list,
list,
row,
preferencesgroup,
preferencespage,
preferencesrow,
view,
notebook,
notebook > header,
notebook > header > tabs > tab {
    border-radius: 0px !important;
    box-shadow: none !important;
}

/* 7. MENÜLER, SAĞ TIK, POPOVER VE ARAÇ İPUÇLARI */
menu,
menuitem,
.popup,
tooltip,
popover,
popover.menu,
popover.background {
    background-color: #0b0f19 !important;
    border: 1px solid #1e293b !important;
    border-radius: 0px !important;
    box-shadow: none !important;
    color: #f8fafc !important;
}
CSSEOF

# CSS Zırhını tüm GTK3 ve GTK4 sistem dizinlerine yay
cp config/includes.chroot/etc/skel/.config/gtk-3.0/gtk.css config/includes.chroot/etc/skel/.config/gtk-4.0/gtk.css
cp config/includes.chroot/etc/skel/.config/gtk-3.0/gtk.css config/includes.chroot/etc/gtk-3.0/gtk.css
cp config/includes.chroot/etc/skel/.config/gtk-3.0/gtk.css config/includes.chroot/etc/gtk-4.0/gtk.css

# ==============================================================================
# GNOME SHELL VE MASAÜSTÜ ARAYÜZÜ TAM KARELEŞTİRME
# ==============================================================================
cat << 'SHELLCSSEOF' >> config/includes.chroot/usr/share/gnome-shell/theme/gnome-shell.css
* {
    border-radius: 0px !important;
}

#panel,
.panel-button,
.popup-menu-content,
.popup-menu-item,
.modal-dialog,
.message-dialog,
.notification-banner,
#notification-banner,
.message-tray,
.osd-window,
.switcher-list,
.search-entry,
.candidate-popup-box,
.app-folder-dialog,
#ArcMenu_MenuBox,
.arc-menu,
.arc-menu-container {
    border-radius: 0px !important;
    box-shadow: none !important;
}

.meles-resource-glass {
    border-radius: 12px !important;
    border: 1px solid rgba(255, 255, 255, 0.28) !important;
    background-color: rgba(18, 22, 29, 0.72) !important;
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.28) !important;
}

#notification-banner, .notification-banner, .modal-dialog {
    background-color: #0b0f19 !important;
    border: 1px solid #38bdf8 !important;
}
SHELLCSSEOF

echo "GTK_THEME=Adwaita-dark" >> config/includes.chroot/etc/environment

# ==============================================================================
# TERMİNAL ZİFİRİ SİYAH DCONF SİSTEM PROFİLİ
# ==============================================================================
cat << 'DCONFEOF' > config/includes.chroot/etc/dconf/profile/user
user-db:user
system-db:local
DCONFEOF

cat << 'DCONFEOF' > config/includes.chroot/etc/dconf/db/local.d/01-terminal
[org/gnome/terminal/legacy/profiles:]
default='b1dcc9dd-5262-4d8d-a863-c897e6d979b9'
list=['b1dcc9dd-5262-4d8d-a863-c897e6d979b9']

[org/gnome/terminal/legacy/profiles:/:b1dcc9dd-5262-4d8d-a863-c897e6d979b9]
visible-name='Meles Titanium'
use-theme-colors=false
background-color='#000000'
foreground-color='#38bdf8'
bold-color-same-as-fg=true
use-system-font=false
font='JetBrains Mono 11'
cell-width-scale=1.0
cell-height-scale=1.0
DCONFEOF

# ==============================================================================
# CANLI OTURUMDA SIYAH TERMİNAL, PANEL MÜHRÜ VE BİLDİRİM KİLİDİ
# ==============================================================================
cat << 'INIT_EOF' > config/includes.chroot/usr/local/bin/meles-init-theme.sh
#!/bin/bash
sleep 2

# Canlı Kullanıcı Ev Dizinine GTK CSS ve Ayar Zırhını Garanti Kopyala
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
cp -f /etc/gtk-3.0/gtk.css "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null || true
cp -f /etc/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true
cp -f /etc/gtk-3.0/settings.ini "$HOME/.config/gtk-3.0/settings.ini" 2>/dev/null || true
cp -f /etc/gtk-4.0/settings.ini "$HOME/.config/gtk-4.0/settings.ini" 2>/dev/null || true

# Mutter ve Masaüstü Koyu Mod Mührü
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.wm.preferences theme 'Adwaita' 2>/dev/null || true

# Terminal profili oluştur, fontu sabitle ve siyaha kilitle
P_ID="b1dcc9dd-5262-4d8d-a863-c897e6d979b9"
gsettings set org.gnome.Terminal.ProfilesList default "$P_ID" 2>/dev/null || true
gsettings set org.gnome.Terminal.ProfilesList list "['$P_ID']" 2>/dev/null || true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P_ID/ visible-name 'Meles Titanium' 2>/dev/null || true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P_ID/ use-theme-colors false 2>/dev/null || true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P_ID/ background-color '#000000' 2>/dev/null || true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P_ID/ foreground-color '#38bdf8' 2>/dev/null || true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P_ID/ use-system-font false 2>/dev/null || true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$P_ID/ font 'JetBrains Mono 11' 2>/dev/null || true

# Kare ikonları temizle, sadece M logosunu ArcMenu olarak panele kilitle
gsettings set org.gnome.shell.extensions.dash-to-panel panel-size 30 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel all-monitors true 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel multi-monitors true 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-bg true 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel trans-bg-color '#000000' 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel trans-use-custom-opacity true 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel trans-panel-opacity 1.0 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel show-apps-icon-visible false 2>/dev/null || true
gsettings set org.gnome.shell.extensions.dash-to-panel show-activities-button false 2>/dev/null || true

# ArcMenu M Logosu
gsettings set org.gnome.shell.extensions.arcmenu menu-button-icon 'Custom_Icon' 2>/dev/null || true
gsettings set org.gnome.shell.extensions.arcmenu custom-menu-button-icon '/usr/share/icons/meleslogo.png' 2>/dev/null || true
gsettings set org.gnome.shell.extensions.arcmenu custom-menu-button-icon-size 24.0 2>/dev/null || true

# Bildirim Eklentisini Etkinleştir
gnome-extensions enable meles-notifications@melesos 2>/dev/null || true
gnome-extensions disable meles-resource-glass@melesos 2>/dev/null || true
gnome-extensions enable ding@rastersoft.com 2>/dev/null || true
gsettings set org.gnome.shell.extensions.ding show-home true 2>/dev/null || true
gsettings set org.gnome.shell.extensions.ding show-trash true 2>/dev/null || true
gsettings set org.gnome.shell.extensions.ding icon-size 'standard' 2>/dev/null || true
INIT_EOF
chmod +x config/includes.chroot/usr/local/bin/meles-init-theme.sh

cat << 'AUTO_EOF' > config/includes.chroot/etc/xdg/autostart/meles-theme-lock.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/meles-init-theme.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Name=Meles Theme Lock
AUTO_EOF

# ==============================================================================
# TÜM PAKETLERDEN SONRA ÇALIŞAN FİNAL DERLEME KANCASI (99)
# ==============================================================================
cat << 'HOOKEOF' > config/hooks/normal/99-finalize-meles-schemas.hook.chroot
#!/bin/sh
echo "[HOOK-99] Eklentiler kuruldu, GSettings ve DConf veritabanları son kez mühürleniyor..."
glib-compile-schemas /usr/share/glib-2.0/schemas/ || true
dconf update || true
HOOKEOF
chmod +x config/hooks/normal/99-finalize-meles-schemas.hook.chroot

# ==============================================================================
# DEBIAN DUVAR KAĞITLARINI SİLME VE XML KAYDEDİCİSİ
# ==============================================================================
cat << 'HOOKEOF' > config/hooks/normal/12-remove-debian-wallpapers.hook.chroot
#!/bin/sh
echo "[HOOK] Orijinal Debian arka planlari siliniyor..."
rm -rf /usr/share/backgrounds/gnome/* 2>/dev/null || true
rm -rf /usr/share/backgrounds/debian/* 2>/dev/null || true
rm -f /usr/share/gnome-background-properties/debian*.xml 2>/dev/null || true
rm -f /usr/share/gnome-background-properties/adwaita*.xml 2>/dev/null || true
HOOKEOF
chmod +x config/hooks/normal/12-remove-debian-wallpapers.hook.chroot

cat << 'XMLEOF' > config/includes.chroot/usr/share/gnome-background-properties/meles-wallpapers.xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
<wallpapers>
  <wallpaper deleted="false">
    <name>Meles Arkaplan 4</name>
    <filename>/usr/share/backgrounds/meles/arkaplan4.png</filename>
    <options>zoom</options>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Meles Arkaplan 1</name>
    <filename>/usr/share/backgrounds/meles/converted_arkaplan1.png</filename>
    <options>zoom</options>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Meles Arkaplan 2</name>
    <filename>/usr/share/backgrounds/meles/converted_arkaplan2.png</filename>
    <options>zoom</options>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Meles Arkaplan 3</name>
    <filename>/usr/share/backgrounds/meles/converted_arkaplan3.png</filename>
    <options>zoom</options>
  </wallpaper>
  <wallpaper deleted="false">
    <name>Meles Arkaplan 5</name>
    <filename>/usr/share/backgrounds/meles/arkaplan5.png</filename>
    <options>zoom</options>
  </wallpaper>
</wallpapers>
XMLEOF

# ==============================================================================
# ÖZEL YAMA 1: DEBIAN İSİMLERİNİ SİLME & HOSTNAME demo YAPMA (meles@demo)
# ==============================================================================
cat << 'HOOKEOF' > config/hooks/normal/10-remove-debian.hook.chroot
#!/bin/sh
echo "[HOOK] Matrix'teki tum Debian isimleri Meles OS, hostname ise demo yapiliyor..."

# Hostname ayarı -> meles@demo
echo "demo" > /etc/hostname
sed -i 's/debian/demo/g' /etc/hosts 2>/dev/null || true
if ! grep -q "demo" /etc/hosts; then
    echo "127.0.1.1 demo" >> /etc/hosts
fi

if [ -f /etc/os-release ]; then
    sed -i 's/Debian GNU\/Linux/Meles OS/g' /etc/os-release
    sed -i 's/Debian/Meles/g' /etc/os-release
    sed -i 's/debian/meles/g' /etc/os-release
    cp /etc/os-release /usr/lib/os-release 2>/dev/null || true
fi

if [ -f /etc/default/grub ]; then
    sed -i 's/GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="Meles OS"/g' /etc/default/grub
    echo 'GRUB_BACKGROUND="/usr/share/plymouth/themes/meles/meleslogo.png"' >> /etc/default/grub
fi

rm -f /usr/share/images/desktop-base/desktop-grub.png 2>/dev/null || true
rm -f /usr/share/desktop-base/active-theme/login/background 2>/dev/null || true
rm -f /usr/share/desktop-base/active-theme/grub/grub-4x3.png 2>/dev/null || true
rm -f /usr/share/desktop-base/active-theme/grub/grub-16x9.png 2>/dev/null || true
find /usr/share/desktop-base -name "*debian*" -delete 2>/dev/null || true
find /usr/share/icons -name "*debian-swirl*" -delete 2>/dev/null || true

mkdir -p /usr/share/images/desktop-base/
cp /usr/share/icons/meleslogo.png /usr/share/images/desktop-base/desktop-grub.png 2>/dev/null || true

rm -f /usr/share/applications/debian-installer-launcher.desktop 2>/dev/null || true
HOOKEOF
chmod +x config/hooks/normal/10-remove-debian.hook.chroot

# ==============================================================================
# DİNAMİK DOSYA AKTARIMI: DUVAR KAĞITLARI, LOGOLAR VE SCRIPT'LER
# ==============================================================================
for WP in arkaplan4.png converted_arkaplan1.png converted_arkaplan2.png converted_arkaplan3.png arkaplan5.png; do
    if [ -f "$WORKSPACE_DIR/arkaplanlar/$WP" ]; then
        cp "$WORKSPACE_DIR/arkaplanlar/$WP" "config/includes.chroot/usr/share/backgrounds/meles/$WP"
    fi
done
rm -f config/includes.chroot/usr/local/bin/melesbrowser.py

if [ -f "$WORKSPACE_DIR/meleslogo.png" ]; then
    cp "$WORKSPACE_DIR/meleslogo.png" "config/includes.chroot/usr/share/icons/meleslogo.png"
    cp "$WORKSPACE_DIR/meleslogo.png" "config/includes.chroot/etc/skel/.face"
    cp "$WORKSPACE_DIR/meleslogo.png" "config/includes.chroot/etc/skel/.face.icon"
fi

# SCP-173 Easter Egg Görselini sisteme gömme
if [ -f "$WORKSPACE_DIR/eastreggphoto.png" ]; then
    mkdir -p config/includes.chroot/usr/share/meles-eggs
    cp "$WORKSPACE_DIR/eastreggphoto.png" "config/includes.chroot/usr/share/meles-eggs/eastreggphoto.png"
fi

# GÖREV ÇUBUĞU VE MELES_GORUNUM KLASÖRÜNÜ ISO İÇİNE GÖMME
if [ -d "$WORKSPACE_DIR/meles_gorunum" ]; then
    mkdir -p config/includes.chroot/usr/local/share/meles_gorunum
    cp -r "$WORKSPACE_DIR/meles_gorunum/"* config/includes.chroot/usr/local/share/meles_gorunum/
    chmod +x config/includes.chroot/usr/local/share/meles_gorunum/*.sh 2>/dev/null || true
    echo ">>> [ZIRH BAŞARILI] Arayüz motoru ISO sistemine kalıcı olarak mühürlendi!"
fi

# Çalışma alanındaki en taze sistem dosyalarını kopyalama
FILES=("meles-hizli-yukleyici.sh" "meleskurulum.sh" "birlesmis_kurulum.sh" "birlesik_kurulum.sh" "meles_gorunum_insaa.sh")
rm -f config/includes.chroot/usr/local/bin/meles-oyun-modu.sh
for FILE in "${FILES[@]}"; do
    if [ -f "$WORKSPACE_DIR/$FILE" ]; then
        cp "$WORKSPACE_DIR/$FILE" "config/includes.chroot/usr/local/bin/$FILE"
        chmod +x "config/includes.chroot/usr/local/bin/$FILE"
        echo ">>> $FILE workspace'ten başarıyla çekildi ve sisteme işlendi!"
    fi
done

if [ -f "$WORKSPACE_DIR/birlesik_kurulum.sh" ] && [ ! -f "$WORKSPACE_DIR/birlesmis_kurulum.sh" ]; then
    cp "$WORKSPACE_DIR/birlesik_kurulum.sh" "config/includes.chroot/usr/local/bin/birlesmis_kurulum.sh"
    chmod +x "config/includes.chroot/usr/local/bin/birlesmis_kurulum.sh"
fi

# ==============================================================================
# GİZLİ TERMİNAL KOMUTLARI VE EASTER EGGS (-j scp173 dahil)
# ==============================================================================
cat << 'HOOKEOF' > config/hooks/normal/11-meles-terminal-mods.hook.chroot
#!/bin/sh
echo "[HOOK] Meles Terminal ve Easter Egg modülleri yükleniyor..."

apt-get update || true
apt-get install -y neofetch eog || true

mkdir -p /usr/share/meles-eggs

cat << 'ASCIIEOF' > /usr/share/meles-eggs/meles_ascii.txt
███╗   ███╗███████╗██╗     ███████╗███████╗
████╗ ████║██╔════╝██║     ██╔════╝██╔════╝
██╔████╔██║█████╗  ██║     █████╗  ███████╗
██║╚██╔╝██║██╔══╝  ██║     ██╔══╝  ╚════██║
██║ ╚═╝ ██║███████╗███████╗███████╗███████║
╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝
ASCIIEOF

cat << 'BASHRC_EOF' >> /etc/bash.bashrc
alias masaustu-kapat="sudo systemctl isolate multi-user.target"
alias masaustu-ac="sudo systemctl isolate graphical.target"
alias neofetch="neofetch --source /usr/share/meles-eggs/meles_ascii.txt --ascii_colors 4 6"



BASHRC_EOF
HOOKEOF
chmod +x config/hooks/normal/11-meles-terminal-mods.hook.chroot

echo ">>> [MODÜL 3] Titanium Arayüz Motoru Başarıyla Mühürlendi!"
