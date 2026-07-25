# 🚀 Meles OS (Beta Core)

<p align="center">
  <img src="https://img.shields.io/badge/Base-Debian_12_Bookworm-red?style=for-the-badge&logo=debian&logoColor=white" />
  <img src="https://img.shields.io/badge/GUI_Engine-PyQt5_WebEngine-blue?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/Desktop-Meles_UI_V5_Pro-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Status-Beta_Active-success?style=for-the-badge" />
</p>

---

## 📌 Meles OS Nedir?

**Meles OS**, Debian 12 (Bookworm) çekirdeği üzerine inşa edilmiş, hafiflik, saf performans ve fütüristik tasarımı odak noktasına alan bağımsız bir Linux dağıtımıdır.

Geleneksel ağır masaüstü ortamlarının aksine, sistem **PyQt5 + WebEngine (Glassmorphism UI)** teknolojisiyle geliştirilmiş özel bir arayüz motoru üzerinden çalışır.

---

## 🌟 Öne Çıkan Özellikler

### 🎨 1. Meles UI V5 Pro Arayüz Motoru
* **Cam Efektli (Glassmorphism) Görev Çubuğu:** Şeffaf, hızlı ve sistem çekirdeğiyle doğrudan haberleşen görev çubuğu.
* **Akıllı Menü Mimarisi:** Sürüklenebilir (Drag & Drop) başlık yapısı, dinamik kısayol sistemi ve entegre güç yönetimi.
* **Canlı Sistem Göstergeleri:** Ağ durumu ve pil yüzdesini gerçek zamanlı takip eden donanım entegrasyonu.

### 🖼️ 2. Özel Görsel Deneyim
* **Anıtkabir & Özel Duvar Kağıtları:** Ayarlar menüsüne tam entegre edilmiş özel yüksek çözünürlüklü arka planlar.
* **Debian Kalıntılarından Arındırılmış Sistem:** Tüm sistem simgeleri, logoları ve marka tanımlamaları Meles OS kimliğiyle değiştirilmiştir.
* **Meles Plymouth Boot Animasyonu:** Özelleştirilmiş açılış/kapanış yükleme ekranı.

### 💻 3. Dahili Araçlar & Ekosistem
* **Meles Browser Lite:** Hafif ve hızlı yerel Python web tarayıcısı.
* **Meles Genel AI:** Sistem yönetimi için dahili yapay zeka asistanı.
* **Calamares Kurulum Entegrasyonu:** Live (RAM) modundan bağımsız, doğrudan disk kurulumu başlatan kurulum motoru.

### 🐚 4. Terminal Modları & Easter Egg'ler
* **`mtaban` Komutu:** Özel ASCII logosu ile hızlı sistem bilgisi ve bakım menüsü.
* **Gizli Terminal Modları:** `-j scp` ve `-j boynagala` gibi özel komut çıktıları.
* **Saf Terminal (RAM Boşaltma):** `masaustu-kapat` komutuyla tüm arayüzü kapatıp saf terminale geçiş imkanı.

---

## 🔨 ISO Derleme (Build) Adımları

Meles OS çalışma alanında projeyi sıfırdan derlemek için terminalde sırasıyla aşağıdaki komutları çalıştırın:

```bash
# 1. Depoyu klonlayın
git clone [https://github.com/ODE-CEO/Meles-Os.git](https://github.com/ODE-CEO/Meles-Os.git)
cd Meles-Os

# 2. Meles UI arayüz motorunu hazırlayın
bash meles_gorunum_insaa.sh

# 3. ISO derleme fırınını ateşleyin (Root hakları gerektirir)
sudo ./baslat.sh
