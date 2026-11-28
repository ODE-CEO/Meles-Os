#!/bin/bash
# ==============================================================================
# MELES OS: BİRLEŞMİŞ KURULUM SİHİRBAZI (GRAFİKSEL ARAYÜZ / GUI)
# ==============================================================================

export GTK_THEME="Adwaita-dark"

# Kurulum tercihlerinin grafik arayüzü terminale düşmeden gösterilir.
if ! command -v yad &> /dev/null; then
    if command -v zenity &> /dev/null; then
        zenity --error --title="Meles Kurulum" \
            --text="Kurulum sihirbazı açılamadı: YAD bileşeni bulunamadı.\nCanlı sistemi yeniden başlatıp kurulum ortamını tekrar deneyin."
    fi
    exit 1
fi

SART_ONAYI=$(yad --form --title="Meles OS - Kurulum 1/2" \
    --width=760 --height=430 --center --fixed --on-top \
    --window-icon="system-software-install" \
    --text="<span font='22' weight='bold' foreground='#38bdf8'>Kuruluma başlamadan önce</span>\n\n<span foreground='#cbd5e1'>Meles OS kurulumuna devam etmek için şartları kabul etmeniz gerekir. Calamares'te seçtiğiniz disk ve bölümlerde yapılacak değişiklikleri dikkatle kontrol edin; biçimlendirme verileri silebilir.</span>\n\n<span foreground='#94a3b8'>Sonraki adımda Meles uygulamaları ve isteğe bağlı kurulum seçeneklerini belirleyeceksiniz.</span>" \
    --columns=1 --margins=22 --borders=10 \
    --field="Meles OS kurulum şartlarını okudum ve kabul ediyorum:CHK" "FALSE" \
    --text-align=left --buttons-layout=center \
    --button="Devam Et:0" --button="İptal:1")

# Kullanıcı X'e veya İptal'e basarsa
if [ $? -ne 0 ] || [ -z "$SART_ONAYI" ]; then
    exit 1
fi

if [ "$SART_ONAYI" != "TRUE" ]; then
    yad --error --title="Şartlar Kabul Edilmedi" \
        --text="Kuruluma devam etmek için şartları kabul etmelisiniz." --center
    exit 1
fi

# İkinci adım: Meles uygulamaları ve isteğe bağlı kurulum tercihleri.
TERCIHLER=$(yad --form --title="Meles OS - Kurulum 2/2" \
    --width=760 --height=520 --center --fixed --on-top \
    --window-icon="system-software-install" \
    --text="<span font='22' weight='bold' foreground='#38bdf8'>Kurulum tercihleri</span>\n\n<span foreground='#cbd5e1'>Meles uygulamalarını ekleyin ve ihtiyacınız olan ek seçenekleri belirleyin. Sürücü/ağ seçenekleri internet bağlantısı gerektirebilir.</span>\n\n<span font='12' weight='bold' foreground='#f8fafc'>UYGULAMA VE DONANIM</span>" \
    --columns=1 --margins=22 --borders=10 \
    --field="Meles uygulamaları kurulsun:CHK" "TRUE" \
    --field="Ekran kartıma uygun ek sürücüler kurulsun:CHK" "FALSE" \
    --field="Kurulumdan önce ağ bağlantılarını yapılandır:CHK" "FALSE" \
    --text-align=left --buttons-layout=center \
    --button="Kuruluma Devam Et:0" --button="Geri:2" --button="İptal:1")
TERCIH_DURUMU=$?

if [ "$TERCIH_DURUMU" -eq 2 ]; then
    exec "$0"
elif [ "$TERCIH_DURUMU" -ne 0 ] || [ -z "$TERCIHLER" ]; then
    exit 1
fi

APP_KUR=$(echo "$TERCIHLER" | awk -F'|' '{print $1}')
DRIVER_KUR=$(echo "$TERCIHLER" | awk -F'|' '{print $2}')
WIFI=$(echo "$TERCIHLER" | awk -F'|' '{print $3}')

# Ağ bağlantısı tercih edildiyse terminal açmadan grafiksel ayarları göster.
if [ "$WIFI" == "TRUE" ]; then
    if command -v nm-connection-editor &> /dev/null; then
        nm-connection-editor &
        yad --info --title="Wi-Fi" --text="Ağ bağlantınızı yaptıktan sonra 'Tamam' butonuna basarak devam edin." --center
    elif command -v gnome-control-center &> /dev/null; then
        gnome-control-center wifi &
        yad --info --title="Ağ Bağlantısı" --text="Ağ bağlantınızı kurduktan sonra Tamam'a basarak devam edin." --center
    else
        yad --warning --title="Ağ Ayarları" \
            --text="Grafiksel ağ ayarları bulunamadı. Kuruluma devam etmeden önce üst menüden ağ bağlantınızı kurun."
    fi
fi

# Seçimleri yönetici yetkisiyle çalışacak kurulum motoruna aktar.
export MELES_DRIVER_KUR="HAYIR"
export MELES_APP_KUR="HAYIR"
[ "$APP_KUR" == "TRUE" ] && export MELES_APP_KUR="EVET"
[ "$DRIVER_KUR" == "TRUE" ] && export MELES_DRIVER_KUR="EVET"

# ==============================================================================
# ANA KURULUM MOTORUNA (meleskurulum.sh) GEÇİŞ
# ==============================================================================
yad --info --title="Hazırlanıyor" --text="Sistem hazırlanıyor... Calamares Kurulum Motoru başlatılıyor." --center --timeout=2 --no-buttons

if [ -f "./meleskurulum.sh" ]; then
    exec bash ./meleskurulum.sh
elif [ -f "/usr/local/bin/meleskurulum.sh" ]; then
    exec /usr/local/bin/meleskurulum.sh
elif command -v meleskurulum.sh &> /dev/null; then
    exec meleskurulum.sh
else
    yad --error --title="Hata" --text="Kritik Dosya Kayıp: 'meleskurulum.sh' bulunamadı!" --center
    exit 1
fi
