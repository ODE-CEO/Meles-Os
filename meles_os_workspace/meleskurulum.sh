#!/bin/bash
# ==============================================================================
# MELES OS KURULUM SİHİRBAZI (OOBE - FULLSCREEN & TITANIUM UI)
# Standart: Teknofest / Enterprise Linux Dağıtım Spesifikasyonu
# ==============================================================================

export QT_QPA_PLATFORM=xcb
if [ "$EUID" -ne 0 ] && command -v xhost &>/dev/null; then
    xhost +SI:localuser:root >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# 0. KULLANICI SEÇİMLERİNİ YAKALAMA (birlesmis_kurulum.sh'tan gelenler)
# ------------------------------------------------------------------------------
MELES_APP_KUR="${MELES_APP_KUR:-EVET}"
MELES_DRIVER_KUR="${MELES_DRIVER_KUR:-HAYIR}"

if [ "$MELES_APP_KUR" == "EVET" ]; then
    echo "[!] Meles uygulamaları kurulumda tutulacak."
else
    echo "[!] Meles uygulamaları hedef sistemden çıkarılacak."
fi

if [ "$MELES_DRIVER_KUR" == "EVET" ]; then
    echo "[!] Ekstra Donanım Sürücüleri (Driver) İndiriliyor..."
fi

# ------------------------------------------------------------------------------
# 1. ROOT YETKİ YÜKSELTİCİ
# ------------------------------------------------------------------------------
if [ "$EUID" -ne 0 ]; then
    MELES_DISP="${DISPLAY:-:0}"
    MELES_XAUTH="${XAUTHORITY:-}"
    MELES_APP_KUR="${MELES_APP_KUR:-EVET}"
    MELES_DRIVER_KUR="${MELES_DRIVER_KUR:-HAYIR}"
    if command -v pkexec &> /dev/null; then
        pkexec env \
            DISPLAY="$MELES_DISP" \
            XAUTHORITY="$MELES_XAUTH" \
            QT_QPA_PLATFORM=xcb \
            MELES_APP_KUR="$MELES_APP_KUR" \
            MELES_DRIVER_KUR="$MELES_DRIVER_KUR" \
            bash "$0" "$@"
        KURULUM_DURUMU=$?
        if [ "$KURULUM_DURUMU" -ne 0 ] && command -v zenity &> /dev/null; then
            zenity --error --title="Meles Kurulum Yetkisi" \
                --text="Kurulum yönetici yetkisi alamadı veya başlatılamadı.\n\nHata kodu: $KURULUM_DURUMU\nYetkilendirme penceresini onaylayıp yeniden deneyin."
        fi
        exit "$KURULUM_DURUMU"
    elif command -v zenity &> /dev/null; then
        zenity --password --title="Meles OS Kurulumu" | sudo -S env \
            DISPLAY="$MELES_DISP" \
            XAUTHORITY="$MELES_XAUTH" \
            QT_QPA_PLATFORM=xcb \
            MELES_APP_KUR="$MELES_APP_KUR" \
            MELES_DRIVER_KUR="$MELES_DRIVER_KUR" \
            bash "$0" "$@"
        KURULUM_DURUMU=$?
        if [ "$KURULUM_DURUMU" -ne 0 ]; then
            zenity --error --title="Meles Kurulum Yetkisi" \
                --text="Yönetici yetkisi alınamadı veya kurulum başlatılamadı.\n\nHata kodu: $KURULUM_DURUMU"
        fi
        exit "$KURULUM_DURUMU"
    else
        echo "Meles Kurulum: Grafiksel yönetici yetkilendirme aracı (pkexec) bulunamadı." >&2
        exit 1
    fi
    exit 0
fi

echo "[+] Meles OS Kurulum Altyapısı Hazırlanıyor..."

# A live install boot can reach the kiosk and desktop launchers at the same
# time. Keep Calamares single-instance so both paths cannot race on its config.
mkdir -p /run/lock
exec 9>/run/lock/meles-calamares.lock
if ! flock -n 9; then
    if command -v zenity &>/dev/null; then
        zenity --info --title="Meles OS Kurulumu" \
            --text="Kurulum aracı zaten açık."
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# 2. BAĞIMLILIK VE PAKET KONTROLÜ
# ------------------------------------------------------------------------------
if ping -q -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
    timedatectl set-ntp true 2>/dev/null || true
fi

if ! command -v calamares &> /dev/null; then
    apt-get update -qq && apt-get install -y calamares calamares-settings-debian -qq
fi
if ! command -v calamares &> /dev/null; then
    if command -v zenity &> /dev/null; then
        zenity --error --title="Meles Kurulum" \
            --text="Calamares kurulamadı. İnternet bağlantısını ve paket kaynaklarını kontrol edip yeniden deneyin."
    fi
    exit 1
fi

BRANDING_DIR="/etc/calamares/branding/melesos"
mkdir -p "$BRANDING_DIR"
mkdir -p /etc/calamares/modules

# ------------------------------------------------------------------------------
# 3. ENDÜSTRİYEL VE MİNİMALİST SVG LOGO
# ------------------------------------------------------------------------------
cat << 'SVGEOF' > "$BRANDING_DIR/meleslogo.svg"
<svg xmlns="http://www.w3.org/2000/svg" width="220" height="220" viewBox="0 0 220 220">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#0284c7"/>
      <stop offset="100%" stop-color="#0369a1"/>
    </linearGradient>
    <linearGradient id="glowGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#38bdf8" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="#0284c7" stop-opacity="0.1"/>
    </linearGradient>
  </defs>
  <rect x="20" y="20" width="180" height="180" rx="40" fill="#0f172a" stroke="#1e293b" stroke-width="4"/>
  <rect x="25" y="25" width="170" height="170" rx="35" fill="none" stroke="url(#glowGrad)" stroke-width="2"/>
  <path d="M60 150 L60 70 L85 115 L110 70 L135 115 L160 70 L160 150" 
        fill="none" stroke="url(#grad1)" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="110" cy="148" r="5" fill="#38bdf8"/>
</svg>
SVGEOF

# ------------------------------------------------------------------------------
# 4. TEKNOFEST STANDARTLARINDA QML SLAYT (KURUMSAL TANITIM)
# ------------------------------------------------------------------------------
cat << 'QMLEOF' > "$BRANDING_DIR/show.qml"
import QtQuick 2.15

Item {
    width: 900; height: 580
    clip: true

    Rectangle {
        anchors.fill: parent
        color: "#0b0f19"

        // Arka Plan Izgara Çizgileri
        Repeater {
            model: 8
            Rectangle {
                x: index * 120; y: 0; width: 1; height: parent.height
                color: "#1e293b"; opacity: 0.2
            }
        }
    }

    // Dinamik Arka Plan Işığı
    Rectangle {
        width: 400; height: 400; radius: 200
        color: "#0284c7"; opacity: 0.05
        x: -50; y: -50
        SequentialAnimation on x {
            loops: Animation.Infinite
            NumberAnimation { to: 150; duration: 8000; easing.type: Easing.InOutQuad }
            NumberAnimation { to: -50; duration: 8000; easing.type: Easing.InOutQuad }
        }
    }

    property int currentSlide: 0
    property variant titles: [
        "Meles OS İşletim Sistemi",
        "Düşük Gecikmeli Çekirdek Mimarisi",
        "Gelişmiş Güvenlik ve İzolasyon",
        "Meles Denetim ve Yönetim Merkezi",
        "Kurulum İcra Ediliyor"
    ]
    property variant subtitles: [
        "Sürüm 2026.08 Titanium | Milli ve Özelleştirilmiş Dağıtım",
        "Yüksek Verimli I/O ve İşlemci Yönetimi",
        "Dahili Güvenlik Duvarı ve Bellek Koruma Protokolleri",
        "Sistem Parametrelerini Gerçek Zamanlı Yapılandırma",
        "Dosya Sistemleri İmzalanıyor ve Yapılandırılıyor"
    ]
    property variant descs: [
        "Meles OS; modern masaüstü standartlarını hafif, optimize edilmiş ve yüksek kararlılık sunan bir altyapıyla bir araya getirir.",
        "Özel bellek yönetim mekanizmaları ve optimize edilmiş çekirdek parametreleri ile donanım kaynaklarını en üst verimle kullanır.",
        "Güvenli önyükleme (Secure Boot) ve yalıtılmış süreç mimarisi sayesinde sistem bütünlüğü kesintisiz korunur.",
        "Meles Suite ve Gelişmiş Ayarlar motoru ile sistem bileşenleri üzerinde tam denetim sağlar.",
        "Seçilen disk bölümleri yapılandırılıyor. Lütfen kurulum tamamlanana kadar cihazınızı kapatmayınız."
    ]

    Item {
        anchors.centerIn: parent
        width: 700; height: 350

        // Üst Başlık (Kategori)
        Text {
            id: subText
            text: subtitles[currentSlide]
            color: "#38bdf8"
            font.pixelSize: 13
            font.bold: true
            font.capitalization: Font.AllUppercase
            font.family: "Ubuntu, Cantarell, sans-serif"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 20
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 500 } }
        }

        // Ana Başlık
        Text {
            id: titleText
            text: titles[currentSlide]
            color: "#f8fafc"
            font.pixelSize: 32
            font.bold: true
            font.family: "Ubuntu, Cantarell, sans-serif"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 55
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 500 } }
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }

        // Açıklama Metni
        Text {
            id: descText
            text: descs[currentSlide]
            color: "#94a3b8"
            font.pixelSize: 16
            font.family: "Ubuntu, Cantarell, sans-serif"
            horizontalAlignment: Text.AlignHCenter
            width: 620
            lineHeight: 1.3
            wrapMode: Text.WordWrap
            anchors.horizontalCenter: parent.horizontalCenter
            y: 130
            opacity: 1
            Behavior on opacity { NumberAnimation { duration: 500 } }
            Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        }

        // Şık Yükleme Göstergesi
        Rectangle {
            y: 240
            width: 500; height: 4
            color: "#1e293b"
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            clip: true

            Rectangle {
                height: parent.height
                width: 140
                radius: 2
                color: "#38bdf8"
                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: -140; to: 500; duration: 2000; easing.type: Easing.InOutQuad }
                }
            }
        }
    }

    Timer {
        interval: 7000; running: true; repeat: true
        onTriggered: {
            titleText.opacity = 0
            titleText.y = 40
            subText.opacity = 0
            descText.opacity = 0
            descText.y = 115
            fadeTimer.start()
        }
    }

    Timer {
        id: fadeTimer; interval: 500; running: false; repeat: false
        onTriggered: {
            currentSlide = (currentSlide + 1) % 5
            titleText.text = titles[currentSlide]
            subText.text = subtitles[currentSlide]
            descText.text = descs[currentSlide]
            titleText.opacity = 1
            titleText.y = 55
            subText.opacity = 1
            descText.opacity = 1
            descText.y = 130
        }
    }
}
QMLEOF

# ------------------------------------------------------------------------------
# 5. TITANIUM DARK MOD QSS TASARIMI
# ------------------------------------------------------------------------------
cat << 'QSSEOF' > "$BRANDING_DIR/stylesheet.qss"
QWidget {
    background-color: #0b0f19;
    color: #f8fafc;
    font-family: "Ubuntu", "Cantarell", "Segoe UI", sans-serif;
    font-size: 14px;
}

/* Sol Kenar Çubuğu (Kurulum Adımları) */
QListView#sidebarMenu {
    background-color: #070a10;
    border: none;
    border-right: 1px solid #1e293b;
    padding-top: 25px;
    font-size: 14px;
    font-weight: 500;
    outline: none;
}
QListView#sidebarMenu::item {
    padding: 14px 20px;
    margin: 4px 12px;
    border-radius: 6px;
    color: #64748b;
}
QListView#sidebarMenu::item:selected {
    background-color: #0f172a;
    color: #38bdf8;
    border-left: 3px solid #38bdf8;
    font-weight: bold;
}

/* Form Elemanları (Giriş Kutuları) */
QLineEdit {
    background-color: #111827;
    border: 1px solid #1e293b;
    border-radius: 6px;
    padding: 10px 14px;
    color: #f8fafc;
    font-size: 14px;
    selection-background-color: #0284c7;
}
QLineEdit:focus {
    border: 1px solid #38bdf8;
    background-color: #0f172a;
}

/* Açılır Menüler (Klavye, Dil vb.) */
QComboBox {
    background-color: #111827;
    border: 1px solid #1e293b;
    border-radius: 6px;
    padding: 8px 14px;
    color: #f8fafc;
}
QComboBox:focus, QComboBox:hover {
    border: 1px solid #38bdf8;
}
QComboBox::drop-down {
    border: none;
    width: 30px;
}
QComboBox QAbstractItemView {
    background-color: #111827;
    border: 1px solid #1e293b;
    color: #f8fafc;
    selection-background-color: #0284c7;
    outline: none;
}

/* Butonlar */
QPushButton {
    background-color: #0284c7;
    color: #ffffff;
    border: none;
    border-radius: 6px;
    padding: 10px 24px;
    font-weight: bold;
    font-size: 13px;
}
QPushButton:hover {
    background-color: #0369a1;
}
QPushButton:pressed {
    background-color: #075985;
}
QPushButton:disabled {
    background-color: #1e293b;
    color: #475569;
}

/* Onay ve Seçim Kutuları */
QCheckBox {
    spacing: 8px;
    color: #cbd5e1;
}
QCheckBox::indicator {
    width: 18px;
    height: 18px;
    border: 1px solid #334155;
    border-radius: 4px;
    background-color: #111827;
}
QCheckBox::indicator:checked {
    background-color: #0284c7;
    border-color: #38bdf8;
}

/* İlerleme Çubuğu (Progress Bar) */
QProgressBar {
    background-color: #111827;
    border: 1px solid #1e293b;
    border-radius: 6px;
    height: 18px;
    text-align: center;
    color: #ffffff;
    font-weight: bold;
}
QProgressBar::chunk {
    background-color: #0284c7;
    border-radius: 5px;
}

/* Kaydırma Çubukları */
QScrollBar:vertical {
    border: none;
    background: #0b0f19;
    width: 6px;
}
QScrollBar::handle:vertical {
    background: #1e293b;
    border-radius: 3px;
    min-height: 25px;
}
QScrollBar::handle:vertical:hover {
    background: #334155;
}
QSSEOF

# ------------------------------------------------------------------------------
# 6. SİSTEM GEREKSİNİMLERİ VE KULLANICI / HOSTNAME YAPILANDIRMASI
# ------------------------------------------------------------------------------
cat << 'CONFEOF' > /etc/calamares/modules/welcome.conf
---
showSupportUrl:         false
showKnownIssuesUrl:     false
showReleaseNotesUrl:    false
requirements:
    requiredStorage:    10.0
    requiredRam:        1.0
    internetCheckUrl:   http://network-test.debian.org/nm
    check:
        - storage
        - ram
        - power
        - internet
        - root
    required:
        - storage
        - root
geoip:
    style:    "json"
    url:      "https://geoip.kde.org/v1/ubiquity"
    selector: ""
languageIcon: "locale"
defaultLanguage: "tr"
CONFEOF

# Kullanıcı Adını 'meles' Olarak Öner, Hostname'i Dinamik Olarak İste
cat << 'USERCONF' > /etc/calamares/modules/users.conf
---
defaultGroups:
    - sudo
    - audio
    - video
    - dialout
    - plugdev
    - netdev
    - users
autologinGroup: autologin
doAutologin: false
sudoersGroup: sudo
setRootPassword: false
doReusePassword: true
defaultUsername: "meles"
USERCONF

# ------------------------------------------------------------------------------
# 7. POST-INSTALL DISK KANCASI (meles@KULLANICI_ADI VE SİSTEM EŞİTLEME)
# ------------------------------------------------------------------------------
cat << 'SHELLCONF' > /etc/calamares/modules/shellprocess.conf
---
dontChroot: false
timeout: 600
script:
    - "-sed -i 's/demo/'\"$(cat /etc/hostname)\"'/g' /etc/hosts"
    - "-glib-compile-schemas /usr/share/glib-2.0/schemas/"
    - "-dconf update"
    - "-for u in /home/*; do cp -r /etc/skel/.config \"$u/\"; chown -R $(basename \"$u\"):$(basename \"$u\") \"$u\"; done"
SHELLCONF

if [ "${MELES_DRIVER_KUR:-HAYIR}" = "EVET" ]; then
    if ! command -v lspci &>/dev/null; then
        if command -v zenity &>/dev/null; then
            zenity --warning --title="Sürücü Seçeneği" \
                --text="Ekran kartı algılama aracı bulunamadı. Ek sürücüler atlanacak; kurulum devam edecek."
        fi
    else
        if lspci | grep -qi nvidia; then
            SURUCU_PAKETLERI="nvidia-driver firmware-misc-nonfree"
        elif lspci | grep -Eqi 'amd|radeon'; then
            SURUCU_PAKETLERI="xserver-xorg-video-amdgpu firmware-amd-graphics mesa-vulkan-drivers"
        elif lspci | grep -qi intel; then
            SURUCU_PAKETLERI="xserver-xorg-video-intel mesa-vulkan-drivers"
        else
            SURUCU_PAKETLERI=""
        fi

        if [ -n "$SURUCU_PAKETLERI" ]; then
            cat >> /etc/calamares/modules/shellprocess.conf << DRIVER_EOF
    - "-apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $SURUCU_PAKETLERI"
DRIVER_EOF
        elif command -v zenity &>/dev/null; then
            zenity --warning --title="Sürücü Seçeneği" \
                --text="Desteklenen ekran kartı algılanmadı. Ek sürücüler atlanacak; kurulum devam edecek."
        fi
    fi
fi

if [ "${MELES_APP_KUR:-HAYIR}" != "EVET" ]; then
    cat >> /etc/calamares/modules/shellprocess.conf << 'APP_REMOVE_EOF'
    - "-rm -f /usr/share/applications/Meles_Browser.desktop /usr/share/applications/Meles_Hizli_Yukleyici.desktop /usr/share/applications/Meles_Surucu_Kurucu.desktop /usr/share/applications/Meles_Gelismis_Ayarlar.desktop /usr/share/applications/Meles_Guncelleme_Merkezi.desktop /usr/share/applications/Meles_Suite.desktop /usr/share/applications/Meles_App.desktop /usr/share/applications/Meles_Cihaz_Baglanti_Merkezi.desktop /usr/share/applications/Meles_Karsilama.desktop /usr/share/applications/Meles_OS_Kur.desktop /etc/skel/Desktop/Meles_Browser.desktop /etc/skel/Desktop/Meles_Hizli_Yukleyici.desktop /etc/skel/Desktop/Meles_Surucu_Kurucu.desktop /etc/skel/Desktop/Meles_OS_Kur.desktop /etc/skel/Masaüstü/Meles_Browser.desktop /etc/skel/Masaüstü/Meles_Hizli_Yukleyici.desktop /etc/skel/Masaüstü/Meles_Surucu_Kurucu.desktop /etc/skel/Masaüstü/Meles_OS_Kur.desktop"
    - "-rm -f /home/*/Desktop/Meles_Browser.desktop /home/*/Desktop/Meles_Hizli_Yukleyici.desktop /home/*/Desktop/Meles_Surucu_Kurucu.desktop /home/*/Desktop/Meles_OS_Kur.desktop /home/*/Masaüstü/Meles_Browser.desktop /home/*/Masaüstü/Meles_Hizli_Yukleyici.desktop /home/*/Masaüstü/Meles_Surucu_Kurucu.desktop /home/*/Masaüstü/Meles_OS_Kur.desktop"
    - "-rm -f /usr/local/bin/melesbrowser.py /usr/local/bin/meles-hizli-yukleyici.sh /usr/local/bin/meles-surucu-kur.sh /usr/local/bin/meles-ayarlar /usr/local/bin/meles-ayarlar-gui /usr/local/bin/meles-guncelle /usr/local/bin/meles-suite /usr/local/bin/meles-app /usr/local/bin/meles-baglanti /usr/local/bin/meles-bekci /usr/local/bin/meles-karsilama /usr/local/bin/meles-araclar /usr/local/bin/meles-ince-ayar /usr/local/bin/meles-tur"
    - "-rm -f /etc/sudoers.d/meles-nopasswd"
    - "-rm -f /etc/xdg/autostart/meles-karsilama.desktop /etc/xdg/autostart/meles-bekci.desktop /etc/skel/.config/autostart/meles-karsilama.desktop /etc/skel/.config/autostart/meles-bekci.desktop"
    - "-rm -rf /usr/local/share/meles_karsilama"
APP_REMOVE_EOF
fi

# ------------------------------------------------------------------------------
# 8. BRANDING DESCRIPTOR (TAM EKRAN ZORLAMA)
# ------------------------------------------------------------------------------
cat << 'DESCEOF' > "$BRANDING_DIR/branding.desc"
---
componentName:           melesos
welcomeStyleCalamares:   false
welcomeExpandingLogo:    true
windowExpanding:         fullscreen
windowPlacement:         center

strings:
    productName:         Meles OS
    shortProductName:    Meles
    version:             2026.08 Titanium
    shortVersion:        2026.08
    versionedName:       Meles OS 2026.08 Titanium
    productUrl:          https://github.com/ODE-CEO/Meles-Os
    supportUrl:          https://github.com/ODE-CEO/Meles-Os
    knownIssuesUrl:      https://github.com/ODE-CEO/Meles-Os
    releaseNotesUrl:     https://github.com/ODE-CEO/Meles-Os

images:
    productLogo:         "meleslogo.svg"
    productIcon:         "meleslogo.svg"

slideshow:               "show.qml"
slideshowAPI:            1

style:
   SidebarBackground:    "#070a10"
   SidebarText:          "#64748b"
   SidebarTextSelect:    "#38bdf8"
   SidebarTextHighlight: "#0f172a"
DESCEOF

# ------------------------------------------------------------------------------
# 9. CALAMARES AYARLARINI BAĞLAMA VE ÇALIŞTIRMA
# ------------------------------------------------------------------------------
CALAMARES_CONFIG="/etc/calamares/settings.conf"
if [ -f "$CALAMARES_CONFIG" ]; then
    sed -i 's/branding: debian/branding: melesos/g' "$CALAMARES_CONFIG"
    sed -i 's/branding: default/branding: melesos/g' "$CALAMARES_CONFIG"
    if grep -q "shellprocess-meles" "$CALAMARES_CONFIG"; then
        sed -i 's/shellprocess-meles/shellprocess/g' "$CALAMARES_CONFIG"
    elif ! grep -qE '^[[:space:]]*-[[:space:]]*shellprocess([[:space:]]|$)' "$CALAMARES_CONFIG"; then
        sed -i '/^[[:space:]]*-[[:space:]]*umount[[:space:]]*$/i\  - shellprocess' "$CALAMARES_CONFIG"
    fi
fi

if [ "$EUID" -ne 0 ]; then
    if command -v zenity &> /dev/null; then
        zenity --error --title="Meles Kurulum Yetkisi" \
            --text="Calamares yönetici yetkisi olmadan başlatılamaz."
    fi
    exit 1
fi

echo "[+] Meles OS Kurulum Arayüzü başlatılıyor..."
CALAMARES_LOG="/var/log/calamares/meles-launch.log"
if ! mkdir -p "$(dirname "$CALAMARES_LOG")"; then
    zenity --error --title="Meles Kurulum" \
        --text="Kurulum günlük dosyası için /var/log/calamares dizini oluşturulamadı."
    exit 1
fi

export GTK_THEME="Adwaita-dark"
export QT_QPA_PLATFORMTHEME="gtk3"
export QT_STYLE_OVERRIDE="Fusion"
export CALAMARES_WINDOW_WIDTH="900"
export CALAMARES_WINDOW_HEIGHT="620"

(
    for _ in $(seq 1 30); do
        if command -v xdotool >/dev/null 2>&1 && command -v xrandr >/dev/null 2>&1; then
            for WINDOW_ID in $(xdotool search --name "Calamares|Meles OS" 2>/dev/null); do
                xdotool windowactivate --sync "$WINDOW_ID" 2>/dev/null || true
                xdotool windowsize "$WINDOW_ID" 900 620 2>/dev/null || true
                SCREEN_W=$(xrandr --current 2>/dev/null | awk '/ connected primary/ {print $4}' | cut -d'x' -f1)
                SCREEN_H=$(xrandr --current 2>/dev/null | awk '/ connected primary/ {print $4}' | cut -d'x' -f2 | cut -d'+' -f1)
                if [[ "$SCREEN_W" =~ ^[0-9]+$ ]] && [[ "$SCREEN_H" =~ ^[0-9]+$ ]]; then
                    POS_X=$(((SCREEN_W - 900) / 2))
                    POS_Y=$(((SCREEN_H - 620) / 2))
                    xdotool windowmove "$WINDOW_ID" "$POS_X" "$POS_Y" 2>/dev/null || true
                fi
                exit 0
            done
        fi
        sleep 0.25
    done
) &
WINDOW_RESIZER_PID=$!

calamares "$@" >"$CALAMARES_LOG" 2>&1
CALAMARES_STATUS=$?
kill "$WINDOW_RESIZER_PID" 2>/dev/null || true
if [ "$CALAMARES_STATUS" -ne 0 ]; then
    zenity --error --title="Calamares Kurulum Hatası" \
        --text="Kurulum aracı hata kodu $CALAMARES_STATUS ile kapandı.\n\nAyrıntılar: $CALAMARES_LOG"
fi
exit "$CALAMARES_STATUS"
