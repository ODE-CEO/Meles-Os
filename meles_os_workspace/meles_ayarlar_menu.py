#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# ==============================================================================
# MELES OS KONTROL MERKEZİ
# Frontend: PyQt5 | Backend: meles-ayarlar (Bash Engine)
# ==============================================================================

import sys
import os
import shutil
import subprocess
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QHBoxLayout,
                             QVBoxLayout, QPushButton, QLabel, QStackedWidget, QFrame)
from PyQt5.QtCore import Qt

def get_backend_script():
    # 1. Öncelik: Sistem genelindeki kurulu binary
    installed_path = shutil.which("meles-ayarlar")
    if installed_path and os.path.exists(installed_path):
        return installed_path
    
    # 2. Öncelik: Yerel geliştirme dizini
    local_dir = os.path.dirname(os.path.abspath(__file__))
    local_script = os.path.join(local_dir, "gelismis_ayarlar.sh")
    if os.path.exists(local_script):
        return local_script
        
    return "/usr/local/bin/meles-ayarlar"

BASH_SCRIPT = get_backend_script()

class MelesControlCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Meles OS Kontrol Merkezi")
        self.resize(950, 650)
        self.initUI()

    def initUI(self):
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QHBoxLayout(central_widget)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # Sidebar
        sidebar = QFrame()
        sidebar.setObjectName("Sidebar")
        sidebar.setFixedWidth(260)
        sidebar_layout = QVBoxLayout(sidebar)
        sidebar_layout.setContentsMargins(15, 30, 15, 20)
        sidebar_layout.setSpacing(10)

        logo_label = QLabel("MELES OS")
        logo_label.setObjectName("LogoText")
        logo_label.setAlignment(Qt.AlignCenter)
        sidebar_layout.addWidget(logo_label)
        sidebar_layout.addSpacing(20)

        self.menu_buttons = []
        categories = [
            ("Sistem Durumu", 0),
            ("Temalar ve Görünüm", 1),
            ("Ağ ve Güvenlik", 2),
            ("Uygulamalar", 3),
            ("Performans", 4),
            ("Bakım ve Onarım", 5)
        ]

        for text, index in categories:
            btn = QPushButton(text)
            btn.setObjectName("MenuButton")
            btn.setCheckable(True)
            btn.clicked.connect(lambda checked, idx=index: self.change_page(idx))
            self.menu_buttons.append(btn)
            sidebar_layout.addWidget(btn)

        sidebar_layout.addStretch()
        
        version_label = QLabel("v2026.08\nMeles Core Engine")
        version_label.setObjectName("VersionText")
        version_label.setAlignment(Qt.AlignCenter)
        sidebar_layout.addWidget(version_label)

        # Pages
        self.pages = QStackedWidget()
        self.pages.setObjectName("ContentArea")

        self.pages.addWidget(self.create_page("Sistem ve Güncellemeler", 
            "İşletim sistemi durumunu izleyin ve sisteminizi güncel tutun.",
            [("Donanım Raporunu Görüntüle", "--ext-info"),
             ("Sistemi Güncelle (APT Upgrade)", "--sys-update"),
             ("Mağaza Uygulamalarını Güncelle", "--flatpak-update")]))

        self.pages.addWidget(self.create_page("Temalar ve Görünüm", 
            "Meles OS masaüstü ortamını özelleştirin.",
            [("Gelişmiş Tema ve Renk Motoru", "--advanced-theme"),
             ("Buton Düzeni ve İkon Paketi", "--set-theme"),
             ("Görev Çubuğu Ayarları", "--set-panel"),
             ("Yazı Tipi ve Sistem Ölçeklemesi", "--font-scale")]))

        self.pages.addWidget(self.create_page("Ağ ve Güvenlik", 
            "Ağ bağlantılarını yapılandırın ve güvenlik duvarını yönetin.",
            [("Ağ Bağlantılarını ve DNS'i Sıfırla", "--net-reset"),
             ("Güvenlik Duvarı (UFW) Aç / Kapat", "--fw-toggle")]))

        self.pages.addWidget(self.create_page("Uygulama İzinleri", 
            "Yüklü paketleri ve sistem bileşenlerini yönetin.",
            [("Tüm Uygulamaları Yönet (Dondur/Kaldır)", "--all-apps"),
             ("Meles Özel Araçlarını Yönet", "--remove-meles-apps")]))

        self.pages.addWidget(self.create_page("Performans Motoru", 
            "İşlemci ve bellek kaynaklarını yönetin.",
            [("İşlemci Güç Modunu Ayarla", "--perf-mode"),
             ("RAM ve Önbelleği Temizle", "--clear-ram"),
             ("Disk Takas (Swappiness) Oranını Ayarla", "--swap-tune")]))

        self.pages.addWidget(self.create_page("Bakım ve Onarım", 
            "Sistem temizliği yapın ve boot parametrelerini yapılandırın.",
            [("Sistemi Onar ve Paketleri Temizle", "--sys-repair"),
             ("Açılış (GRUB) Ekranını Özelleştir", "--boot-opts")]))

        main_layout.addWidget(sidebar)
        main_layout.addWidget(self.pages)

        self.apply_styles()
        self.menu_buttons[0].setChecked(True)
        self.pages.setCurrentIndex(0)

    def change_page(self, index):
        for idx, btn in enumerate(self.menu_buttons):
            btn.setChecked(idx == index)
        self.pages.setCurrentIndex(index)

    def run_bash_command(self, arg):
        target_script = get_backend_script()
        subprocess.Popen(['bash', target_script, arg])

    def create_page(self, title_text, desc_text, actions):
        page = QWidget()
        layout = QVBoxLayout(page)
        layout.setContentsMargins(40, 50, 40, 40)
        layout.setSpacing(20)

        title = QLabel(title_text)
        title.setObjectName("PageTitle")
        layout.addWidget(title)

        desc = QLabel(desc_text)
        desc.setObjectName("PageDesc")
        desc.setWordWrap(True)
        layout.addWidget(desc)
        layout.addSpacing(20)

        for name, arg in actions:
            btn = QPushButton(f"  {name}")
            btn.setObjectName("ActionButton")
            btn.setCursor(Qt.PointingHandCursor)
            btn.clicked.connect(lambda checked, a=arg: self.run_bash_command(a))
            layout.addWidget(btn)

        layout.addStretch()
        return page

    def apply_styles(self):
        style_sheet = """
        QMainWindow {
            background-color: #121212;
        }
        #Sidebar {
            background-color: #1A1A1D;
            border-right: 1px solid #2D2D30;
        }
        #LogoText {
            color: #1E90FF;
            font-size: 22px;
            font-weight: bold;
            font-family: 'Ubuntu', sans-serif;
        }
        #VersionText {
            color: #666666;
            font-size: 12px;
        }
        #MenuButton {
            background-color: transparent;
            color: #A0A0A0;
            font-size: 14px;
            font-weight: 500;
            text-align: left;
            padding: 12px 15px;
            border-radius: 6px;
            border: none;
        }
        #MenuButton:hover {
            background-color: #2D2D30;
            color: #FFFFFF;
        }
        #MenuButton:checked {
            background-color: #1E90FF;
            color: #FFFFFF;
        }
        #ContentArea {
            background-color: #121212;
        }
        #PageTitle {
            color: #FFFFFF;
            font-size: 26px;
            font-weight: bold;
            font-family: 'Ubuntu', sans-serif;
        }
        #PageDesc {
            color: #888888;
            font-size: 14px;
            margin-bottom: 15px;
        }
        #ActionButton {
            background-color: #1E1E24;
            color: #E0E0E0;
            font-size: 15px;
            font-weight: 500;
            text-align: left;
            padding: 16px 20px;
            border-radius: 8px;
            border: 1px solid #2D2D30;
        }
        #ActionButton:hover {
            background-color: #2A2A35;
            border: 1px solid #1E90FF;
            color: #FFFFFF;
        }
        #ActionButton:pressed {
            background-color: #1E90FF;
            color: #FFFFFF;
        }
        """
        self.setStyleSheet(style_sheet)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MelesControlCenter()
    window.show()
    sys.exit(app.exec_())
