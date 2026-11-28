#!/bin/bash
# ==============================================================================
# MELES OS: AĞ VE AYGIT BAĞLANTI YÖNETİCİSİ
# Standart: Kurumsal Masaüstü ve Donanım Yönetim Spesifikasyonu
# ==============================================================================

export GTK_THEME="Yaru-blue-dark"
SCRIPT_NAME="Meles OS Aygıt ve Bağlantı Merkezi"
IKON="network-wireless"

# Gerekli Temel Paket Kontrolü
if ! command -v yad &> /dev/null; then
    echo "[-] Hata: YAD arayüz motoru sistemde bulunamadı."
    exit 1
fi

# ------------------------------------------------------------------------------
# 1. BLUETOOTH AYGIT VE BAĞLANTI MODÜLÜ
# ------------------------------------------------------------------------------
bluetooth_menu() {
    # Donanım ve Servis Kontrolü
    BT_STATE=$(rfkill list bluetooth 2>/dev/null | grep -i "soft blocked: no")
    if [ -z "$BT_STATE" ]; then
        rfkill unblock bluetooth 2>/dev/null || true
        pkexec systemctl start bluetooth 2>/dev/null || true
    fi

    SECIM=$(yad --list --title="Bluetooth Donanım Yönetimi" --width=540 --height=340 --center \
        --window-icon="bluetooth" \
        --text="<span font='12' weight='bold'>Bluetooth Aygıt İşlemleri</span>\nYapmak istediğiniz işlemi seçiniz:" \
        --column="İşlem Kodu" --column="Açıklama" \
        "TARA_BAGLAN" "Çevredeki görünür aygıtları tara ve eşleştir" \
        "ESLESMIS_CIHAZLAR" "Kayıtlı ve eşleşmiş aygıtları listele / bağlan" \
        "PANEL_AC" "Gelişmiş Bluetooth kontrol panelini başlat" \
        "SERVIS_SIFIRLA" "Bluetooth alt sistemini ve bağdaştırıcıyı yeniden başlat" \
        --button="İleri:0" --button="İptal:1")

    [ $? -ne 0 ] && return

    ISLEM=$(echo "$SECIM" | awk -F'|' '{print $1}')

    if [ "$ISLEM" == "TARA_BAGLAN" ]; then
        (
            echo "10"; echo "# Bağdaştırıcı etkinleştiriliyor..."
            bluetoothctl power on > /dev/null 2>&1
            echo "30"; echo "# Çevredeki aygıtlar taranıyor (5 saniye)..."
            bluetoothctl --timeout 5 scan on > /dev/null 2>&1
            echo "80"; echo "# Donanım listesi doğrulanıyor..."
            sleep 1
            echo "100"; echo "# Tarama tamamlandı."
        ) | yad --progress --title="Aygıt Taraması" --width=380 --center --auto-close

        LIST_ITEMS=""
        while IFS= read -r line; do
            MAC=$(echo "$line" | awk '{print $2}')
            NAME=$(echo "$line" | cut -d' ' -f3-)
            [ -n "$MAC" ] && [ -n "$NAME" ] && LIST_ITEMS="$LIST_ITEMS \"$MAC\" \"$NAME\""
        done < <(bluetoothctl devices)

        if [ -z "$LIST_ITEMS" ]; then
            yad --warning --title="Aygıt Bulunamadı" \
                --text="Çevrede eşleşmeye hazır aygıt tespit edilemedi.\nAygıtınızın görünür modda olduğundan emin olunuz." \
                --width=420 --center --button="Tamam:0"
            return
        fi

        SELECTED_MAC=$(echo "$LIST_ITEMS" | xargs yad --list --title="Aygıt Eşleştirme" --width=540 --height=360 --center \
            --text="Bağlanmak istediğiniz aygıtı seçiniz:" \
            --column="MAC Adresi" --column="Aygıt Tanımı" \
            --button="Bağlan:0" --button="İptal:1")

        if [ $? -eq 0 ] && [ -n "$SELECTED_MAC" ]; then
            TARGET_MAC=$(echo "$SELECTED_MAC" | awk -F'|' '{print $1}')
            
            yad --info --text="Aygıt ile eşleştirme yapılıyor: $TARGET_MAC\nLütfen bekleyiniz..." \
                --center --timeout=2 --no-buttons

            bluetoothctl pair "$TARGET_MAC" > /dev/null 2>&1
            bluetoothctl trust "$TARGET_MAC" > /dev/null 2>&1
            CONNECT_RES=$(bluetoothctl connect "$TARGET_MAC")

            if [[ "$CONNECT_RES" == *"Successful"* ]]; then
                yad --info --title="Bağlantı Kuruldu" --text="Aygıt başarıyla sisteme bağlandı." --center --timeout=3
            else
                yad --error --title="Bağlantı Hatası" --text="Aygıta bağlanılamadı.\nDetay: $CONNECT_RES" --center
            fi
        fi

    elif [ "$ISLEM" == "ESLESMIS_CIHAZLAR" ]; then
        PAIRED_ITEMS=""
        while IFS= read -r line; do
            MAC=$(echo "$line" | awk '{print $2}')
            NAME=$(echo "$line" | cut -d' ' -f3-)
            [ -n "$MAC" ] && PAIRED_ITEMS="$PAIRED_ITEMS \"$MAC\" \"$NAME\""
        done < <(bluetoothctl paired-devices)

        if [ -z "$PAIRED_ITEMS" ]; then
            yad --info --title="Kayıtlı Aygıt Yok" --text="Sistemde kayıtlı eşleşmiş Bluetooth aygıtı bulunamadı." --center --timeout=3
            return
        fi

        SELECTED_DEV=$(echo "$PAIRED_ITEMS" | xargs yad --list --title="Eşleşmiş Aygıtlar" --width=520 --height=340 --center \
            --text="Yeniden bağlanmak istediğiniz kayıtlı aygıtı seçiniz:" \
            --column="MAC Adresi" --column="Aygıt Tanımı" \
            --button="Bağlan:0" --button="Kaldır:2" --button="İptal:1")
        
        RET=$?
        TARGET_MAC=$(echo "$SELECTED_DEV" | awk -F'|' '{print $1}')

        if [ $RET -eq 0 ] && [ -n "$TARGET_MAC" ]; then
            bluetoothctl connect "$TARGET_MAC"
            yad --info --text="Bağlantı komutu iletildi: $TARGET_MAC" --center --timeout=2
        elif [ $RET -eq 2 ] && [ -n "$TARGET_MAC" ]; then
            bluetoothctl remove "$TARGET_MAC"
            yad --info --text="Aygıt eşleştirmesi sistemden kaldırıldı." --center --timeout=2
        fi

    elif [ "$ISLEM" == "PANEL_AC" ]; then
        if command -v blueman-manager &> /dev/null; then
            blueman-manager &
        elif command -v gnome-control-center &> /dev/null; then
            gnome-control-center bluetooth &
        fi
    elif [ "$ISLEM" == "SERVIS_SIFIRLA" ]; then
        pkexec systemctl restart bluetooth
        yad --info --text="Bluetooth alt sistemi başarıyla yeniden başlatıldı." --center --timeout=2
    fi
}

# ------------------------------------------------------------------------------
# 2. KABLOSUZ AĞ (WI-FI) BAĞLANTI MODÜLÜ
# ------------------------------------------------------------------------------
wifi_connect_menu() {
    (
        echo "20"; echo "# Kablosuz ağ kartı taranıyor..."
        nmcli dev wifi rescan > /dev/null 2>&1 || true
        echo "70"; echo "# Erişim noktaları listeleniyor..."
        sleep 1
        echo "100"; echo "# Liste güncellendi."
    ) | yad --progress --title="Wi-Fi Taraması" --width=380 --center --auto-close

    WIFI_RAW=$(nmcli -t -f IN-USE,SSID,BARS,SECURITY dev wifi list | grep -v '^$')

    if [ -z "$WIFI_RAW" ]; then
        yad --error --title="Ağ Bulunamadı" --text="Çevrede kablosuz erişim noktası tespit edilemedi." --center --timeout=3
        return
    fi

    WIFI_LIST=""
    while IFS=: read -r in_use ssid bars security; do
        [ -z "$ssid" ] && continue
        DURUM="Hazır"
        [ "$in_use" == "*" ] && DURUM="[BAĞLI]"
        [ -z "$security" ] && security="Açık (Şifresiz)"
        WIFI_LIST="$WIFI_LIST \"$DURUM\" \"$ssid\" \"$bars\" \"$security\""
    done <<< "$WIFI_RAW"

    SECILEN_AG=$(echo "$WIFI_LIST" | xargs yad --list --title="Meles Ağ Yöneticisi" \
        --width=640 --height=420 --center --window-icon="network-wireless" \
        --text="<span font='12' weight='bold'>Kullanılabilir Kablosuz Ağlar</span>\nBağlanmak istediğiniz ağı seçiniz:" \
        --column="Durum" --column="SSID (Ağ Adı)" --column="Sinyal" --column="Güvenlik Protokolü" \
        --button="Bağlan:0" --button="İptal:1")

    [ $? -ne 0 ] && return

    SSID=$(echo "$SECILEN_AG" | awk -F'|' '{print $2}')
    GUVENLIK=$(echo "$SECILEN_AG" | awk -F'|' '{print $4}')

    if [ -n "$SSID" ]; then
        if [[ "$GUVENLIK" == *"Açık"* ]]; then
            nmcli dev wifi connect "$SSID"
            yad --info --text="'$SSID' ağına bağlantı kuruldu." --center --timeout=3
        else
            SIFRE=$(yad --entry --title="Kimlik Doğrulama" --center --width=400 \
                --text="<b>$SSID</b> ağı için güvenlik anahtarını giriniz:" --hide-text \
                --button="Kimlik Doğrula:0" --button="İptal:1")
            
            if [ $? -eq 0 ] && [ -n "$SIFRE" ]; then
                RES=$(nmcli dev wifi connect "$SSID" password "$SIFRE" 2>&1)
                if [[ "$RES" == *"successfully activated"* ]] || [[ "$RES" == *"başarıyla"* ]]; then
                    yad --info --title="İşlem Başarılı" --text="<b>$SSID</b> ağına başarıyla bağlanıldı." --center --timeout=3
                else
                    yad --error --title="Kimlik Doğrulama Hatası" --text="Bağlantı kurulamadı:\n$RES" --center
                fi
            fi
        fi
    fi
}

# ------------------------------------------------------------------------------
# 3. KABLOSUZ EKRAN YANSITMA (ADB / SCRCPY KÖPRÜSÜ)
# ------------------------------------------------------------------------------
phone_mirror_menu() {
    SECIM=$(yad --form --title="Mobil Ekran Köprüsü" --width=500 --center \
        --text="<span font='12' weight='bold'>Android Kablosuz Ekran Yansıtma</span>\nHedef cihaz ve bilgisayarın aynı yerel ağda olduğundan emin olunuz." \
        --field="Hedef Cihaz Yerel IP:":TEXT "192.168.1." \
        --field="Hata Ayıklama Portu:":TEXT "5555" \
        --button="Köprüyü Başlat:0" --button="İptal:1")

    if [ $? -eq 0 ]; then
        IP=$(echo "$SECIM" | awk -F'|' '{print $1}')
        PORT=$(echo "$SECIM" | awk -F'|' '{print $2}')
        [ -z "$PORT" ] && PORT="5555"

        if ! command -v scrcpy &> /dev/null; then
            yad --info --text="Gerekli ekran bileşeni (scrcpy) yükleniyor..." --center --timeout=2 --no-buttons
            pkexec apt update -qq && pkexec apt install -y scrcpy adb -qq
        fi

        adb disconnect > /dev/null 2>&1 || true
        adb connect "$IP:$PORT"
        scrcpy --tcpip="$IP:$PORT" --always-on-top &
    fi
}

# ------------------------------------------------------------------------------
# 4. YEREL AĞ DOSYA PAYLAŞIM SUNUCUSU
# ------------------------------------------------------------------------------
quick_file_share() {
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    PORT="8888"
    SHARE_DIR="$HOME"

    python3 -m http.server "$PORT" --directory "$SHARE_DIR" > /dev/null 2>&1 &
    SERVER_PID=$!

    yad --info --title="Yerel Ağ Dosya Sunucusu" --width=520 --center \
        --window-icon="folder-remote" \
        --text="<span font='12' weight='bold'>Yerel Ağ Dosya Servisi Aktif</span>\n\nAynı ağdaki cihazların tarayıcısından aşağıdaki adrese erişebilirsiniz:\n\n<span font='14' color='#38bdf8'><b>http://$LOCAL_IP:$PORT</b></span>\n\n<i>Servisi sonlandırmak için pencereyi kapatınız.</i>" \
        --button="Servisi Durdur:0"

    kill "$SERVER_PID" 2>/dev/null || true
}

# ------------------------------------------------------------------------------
# 5. YEREL AĞ CİHAZ KEŞİF MOTORU
# ------------------------------------------------------------------------------
scan_lan_devices() {
    (
        echo "30"; echo "# ARP tablosu sorgulanıyor..."
        sleep 1
        echo "70"; echo "# Ağ bağdaştırıcıları analiz ediliyor..."
        ip neigh show > /tmp/lan_devices.txt
        echo "100"; echo "# Tarama tamamlandı."
    ) | yad --progress --title="Ağ Analizi" --width=380 --center --auto-close

    DEVS=$(cat /tmp/lan_devices.txt | grep -v "FAILED" | awk '{print "\""$1"\" \"" $5 "\" \"" $6 "\""}')
    
    if [ -z "$DEVS" ]; then
        yad --info --text="Ağ üzerinde aktif başka uç birim tespit edilemedi." --center --timeout=3
    else
        echo "$DEVS" | xargs yad --list --title="Yerel Ağ Uç Birimleri" --width=560 --height=360 --center \
            --text="<span font='12' weight='bold'>Modeme Bağlı Aktif Düğümler</span>" \
            --column="IP Adresi" --column="Fiziksel (MAC) Adres" --column="Arayüz" \
            --button="Kapat:0"
    fi
}

# ------------------------------------------------------------------------------
# 6. KABLOSUZ ERİŞİM NOKTASI (HOTSPOT) MODÜLÜ
# ------------------------------------------------------------------------------
hotspot_toggle() {
    HOTSPOT_ACTIVE=$(nmcli con show --active | grep -i "hotspot")
    
    if [ -n "$HOTSPOT_ACTIVE" ]; then
        nmcli con down Hotspot > /dev/null 2>&1 || true
        yad --info --text="Kablosuz erişim noktası (Hotspot) devre dışı bırakıldı." --center --timeout=3
    else
        nmcli dev wifi hotspot ssid "Meles_OS_AP" password "meles2026" > /dev/null 2>&1
        yad --info --title="Erişim Noktası Başlatıldı" --center \
            --text="<span font='12' weight='bold'>Kablosuz Erişim Noktası Aktif</span>\n\n<b>SSID:</b> Meles_OS_AP\n<b>Güvenlik Anahtarı:</b> meles2026" \
            --button="Tamam:0"
    fi
}

# ==============================================================================
# ANA KONTROL DÖNGÜSÜ
# ==============================================================================
while true; do
    ANA_SECIM=$(yad --list --title="$SCRIPT_NAME" --width=620 --height=440 --center \
        --window-icon="$IKON" \
        --text="<span font='14' weight='bold'>Meles OS Aygıt ve Bağlantı Merkezi</span>\nKablosuz donanımları, yerel ağ servislerini ve aygıt eşleştirmelerini yönetin." \
        --column="Modül" --column="Fonksiyonel Açıklama" \
        "Kablosuz Ağlar (Wi-Fi)" "Çevredeki kablosuz ağları tara ve kimlik doğrulaması yap" \
        "Bluetooth Donanımları" "Aygıt taraması, eşleştirme ve bağdaştırıcı yönetimi" \
        "Ekran Yansıtma (ADB)" "Mobil cihaz ekranını yerel ağ üzerinden yansıt (scrcpy)" \
        "Yerel Dosya Servisi" "Yerel ağ üzerinden doğrudan dosya paylaşım sunucusu başlat" \
        "Ağ Düğüm Keşfi" "Aynı yerel ağdaki bağlı cihazların IP ve MAC tablosunu incele" \
        "Erişim Noktası (Hotspot)" "Bilgisayarı kablosuz erişim noktasına (AP) dönüştür" \
        --button="Seç:0" --button="Kapat:1")

    [ $? -ne 0 ] && exit 0

    SECILEN=$(echo "$ANA_SECIM" | awk -F'|' '{print $1}')

    case "$SECILEN" in
        *"Kablosuz Ağlar"*) wifi_connect_menu ;;
        *"Bluetooth"*) bluetooth_menu ;;
        *"Ekran Yansıtma"*) phone_mirror_menu ;;
        *"Yerel Dosya"*) quick_file_share ;;
        *"Ağ Düğüm"*) scan_lan_devices ;;
        *"Erişim Noktası"*) hotspot_toggle ;;
        *) exit 0 ;;
    esac
done
