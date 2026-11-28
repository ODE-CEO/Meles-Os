#!/usr/bin/env python3
import subprocess
import sys

import psutil
from PyQt5.QtCore import QProcess, Qt, QTimer
from PyQt5.QtWidgets import (
    QApplication,
    QFrame,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QProgressBar,
    QPushButton,
    QVBoxLayout,
    QWidget,
)


class GlassCard(QFrame):
    def __init__(self, title, description):
        super().__init__()
        self.setObjectName("glassCard")
        layout = QVBoxLayout(self)
        layout.setContentsMargins(22, 18, 22, 20)
        layout.setSpacing(10)

        heading = QLabel(title)
        heading.setObjectName("cardHeading")
        detail = QLabel(description)
        detail.setObjectName("muted")
        detail.setWordWrap(True)
        layout.addWidget(heading)
        layout.addWidget(detail)
        self.content = layout


class MelesGlassCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Meles Kontrol Merkezi")
        self.setMinimumSize(820, 620)
        self.resize(940, 700)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.process = None
        self.current_action = None
        self.process_output = ""
        self.gpu_available = False
        self.cpu_profile_available = False

        root = QWidget()
        root.setObjectName("windowSurface")
        self.setCentralWidget(root)
        layout = QVBoxLayout(root)
        layout.setContentsMargins(28, 24, 28, 24)
        layout.setSpacing(16)

        title = QLabel("MELES  /  KONTROL MERKEZİ")
        title.setObjectName("title")
        subtitle = QLabel("Donanım sürücüleri ve akıllı kaynak tasarrufu")
        subtitle.setObjectName("muted")
        layout.addWidget(title)
        layout.addWidget(subtitle)

        usage_row = QHBoxLayout()
        usage_row.setSpacing(14)
        self.cpu_value, self.cpu_bar = self.add_usage_card(
            usage_row, "İŞLEMCİ", "Anlık toplam kullanım"
        )
        self.memory_value, self.memory_bar = self.add_usage_card(
            usage_row, "BELLEK", "Kullanılan RAM oranı"
        )
        layout.addLayout(usage_row)

        self.gpu_card = GlassCard(
            "Ekran kartı sürücüleri",
            "Donanımı algılar ve Debian depolarındaki uygun sürücüleri kurar.",
        )
        self.gpu_status = QLabel()
        self.gpu_status.setObjectName("status")
        self.gpu_status.setWordWrap(True)
        self.gpu_card.content.addWidget(self.gpu_status)
        gpu_buttons = QHBoxLayout()
        self.detect_button = QPushButton("Donanımı Tara")
        self.detect_button.clicked.connect(self.detect_gpu)
        self.driver_button = QPushButton("Uygun Sürücüyü Kur")
        self.driver_button.setObjectName("primaryButton")
        self.driver_button.clicked.connect(self.install_driver)
        gpu_buttons.addWidget(self.detect_button)
        gpu_buttons.addWidget(self.driver_button)
        self.gpu_card.content.addLayout(gpu_buttons)
        layout.addWidget(self.gpu_card)

        self.resource_card = GlassCard(
            "Kaynak tasarrufu",
            "ZRAM bellek baskısını azaltmaya, Early OOM sistemin bellek tamamen dolmadan yanıt vermeye devam etmesine yardımcı olur.",
        )
        self.resource_status = QLabel("Bellek servisleri denetleniyor…")
        self.resource_status.setObjectName("status")
        self.resource_status.setWordWrap(True)
        self.resource_card.content.addWidget(self.resource_status)
        resource_buttons = QHBoxLayout()
        self.memory_button = QPushButton("Bellek korumasını etkinleştir")
        self.memory_button.setObjectName("primaryButton")
        self.memory_button.clicked.connect(self.toggle_memory_services)
        self.cpu_button = QPushButton("İşlemci: Tasarruf modu")
        self.cpu_button.clicked.connect(self.toggle_cpu_profile)
        resource_buttons.addWidget(self.memory_button)
        resource_buttons.addWidget(self.cpu_button)
        self.resource_card.content.addLayout(resource_buttons)
        layout.addWidget(self.resource_card)

        self.log = QLabel("Hazır. Değişiklik gerektiren işlemler yönetici onayı ister.")
        self.log.setObjectName("muted")
        self.log.setWordWrap(True)
        layout.addWidget(self.log)
        layout.addStretch(1)

        self.setStyleSheet(
            """
            QWidget#windowSurface {
                background-color: rgba(15, 18, 22, 238);
                border: 1px solid rgba(255, 255, 255, 85);
                border-radius: 24px;
                color: #f7f7f7;
                font-family: "Cantarell", "Noto Sans", sans-serif;
            }
            QFrame#glassCard {
                background-color: rgba(255, 255, 255, 20);
                border: 1px solid rgba(255, 255, 255, 60);
                border-top-color: rgba(255, 255, 255, 105);
                border-radius: 18px;
            }
            QLabel#title { font-size: 21px; font-weight: 700; letter-spacing: 2px; }
            QLabel#cardHeading { font-size: 16px; font-weight: 700; color: #ffffff; }
            QLabel#muted { color: #c4c7cc; font-size: 12px; }
            QLabel#status { color: #f1f1f1; font-size: 13px; padding: 3px 0; }
            QPushButton {
                background-color: rgba(255, 255, 255, 28);
                color: white; border: 1px solid rgba(255, 255, 255, 90);
                border-radius: 11px; padding: 11px 16px; font-weight: 600;
            }
            QPushButton:hover { background-color: rgba(255, 255, 255, 55); }
            QPushButton:disabled { color: #8b8b8b; }
            QPushButton#primaryButton {
                background-color: rgba(255, 255, 255, 225);
                color: #101114; border-color: white;
            }
            QPushButton#primaryButton:hover { background-color: white; }
            QProgressBar {
                height: 12px; border: 1px solid rgba(255,255,255,70);
                border-radius: 6px; background: rgba(0,0,0,100);
                color: transparent;
            }
            QProgressBar::chunk {
                border-radius: 5px; background: qlineargradient(
                    x1:0, y1:0, x2:1, y2:0,
                    stop:0 rgba(255,255,255,150), stop:1 #ffffff);
            }
            """
        )

        self.timer = QTimer(self)
        self.timer.timeout.connect(self.refresh_usage)
        self.timer.start(3000)
        self.refresh_usage()
        self.detect_gpu()
        self.refresh_resource_state()

    def add_usage_card(self, row, name, description):
        card = GlassCard(name, description)
        value = QLabel("—")
        value.setObjectName("cardHeading")
        bar = QProgressBar()
        bar.setRange(0, 100)
        bar.setTextVisible(False)
        card.content.addWidget(value)
        card.content.addWidget(bar)
        row.addWidget(card)
        return value, bar

    def refresh_usage(self):
        cpu = psutil.cpu_percent(interval=None)
        memory = psutil.virtual_memory()
        self.cpu_value.setText(f"{cpu:.0f}%")
        self.cpu_bar.setValue(round(cpu))
        self.memory_value.setText(f"{memory.percent:.0f}%  ·  {memory.used / (1024 ** 3):.1f} / {memory.total / (1024 ** 3):.1f} GB")
        self.memory_bar.setValue(round(memory.percent))

    def detect_gpu(self):
        try:
            result = subprocess.run(
                ["lspci", "-nn"], check=True, capture_output=True, text=True
            )
        except (OSError, subprocess.CalledProcessError) as error:
            self.gpu_status.setText(f"Donanım bilgisi okunamadı: {error}")
            self.gpu_available = False
            self.set_actions_enabled(self.process is None)
            return

        devices = [
            line.strip()
            for line in result.stdout.splitlines()
            if any(key in line.lower() for key in ("vga", "3d controller", "display controller"))
        ]
        self.gpu_status.setText("\n".join(devices) if devices else "Ekran kartı bulunamadı.")
        self.gpu_available = bool(devices)
        self.set_actions_enabled(self.process is None)

    def start_privileged_action(self, action):
        if self.process is not None:
            return
        self.current_action = action
        self.process_output = ""
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.read_process_output)
        self.process.readyReadStandardError.connect(self.read_process_output)
        self.process.finished.connect(self.finish_privileged_action)
        self.process.errorOccurred.connect(self.handle_process_error)
        self.set_actions_enabled(False)
        self.log.setText("İşlem başlatılıyor; gerekirse yönetici onayını verin…")
        self.process.start(
            "pkexec", ["/usr/local/bin/meles-sistem-araci.sh", action]
        )

    def read_process_output(self):
        if self.process is None:
            return
        output = bytes(self.process.readAllStandardOutput()).decode(errors="replace")
        error = bytes(self.process.readAllStandardError()).decode(errors="replace")
        text = (output + error).strip()
        if text:
            self.process_output += text + "\n"
            self.log.setText(self.process_output[-600:])

    def finish_privileged_action(self, exit_code, _exit_status):
        self.read_process_output()
        self.process = None
        self.set_actions_enabled(True)
        if exit_code == 0:
            if self.log.text().startswith("İşlem başlatılıyor"):
                self.log.setText("İşlem tamamlandı.")
            self.refresh_resource_state()
            if self.current_action == "install-drivers" and QMessageBox.question(
                self,
                "İşlem tamamlandı",
                "Sürücü değişikliklerinin uygulanması için sistemi şimdi yeniden başlatmak ister misiniz?",
                QMessageBox.Yes | QMessageBox.No,
                QMessageBox.No,
            ) == QMessageBox.Yes:
                subprocess.Popen(["systemctl", "reboot"])
        else:
            reason = self.process_output[-350:].strip()
            self.log.setText(
                f"İşlem başarısız (kod {exit_code}). {reason or 'Yönetici onayı veya paket kurulumunu kontrol edin.'}"
            )
        self.current_action = None

    def handle_process_error(self, _error):
        if self.process is None:
            return
        reason = self.process.errorString()
        self.process = None
        self.current_action = None
        self.set_actions_enabled(True)
        self.log.setText(f"Yetki işlemi başlatılamadı: {reason}")

    def set_actions_enabled(self, enabled):
        self.detect_button.setEnabled(enabled)
        self.driver_button.setEnabled(enabled and self.gpu_available)
        self.memory_button.setEnabled(enabled)
        self.cpu_button.setEnabled(enabled and self.cpu_profile_available)

    def install_driver(self):
        if QMessageBox.question(
            self,
            "Sürücü kurulumu",
            "Algılanan ekrana uygun sürücü paketleri Debian depolarından kurulacak. Devam edilsin mi?",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No,
        ) == QMessageBox.Yes:
            self.start_privileged_action("install-drivers")

    def refresh_resource_state(self):
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "zramswap.service", "earlyoom.service"],
                capture_output=True,
                text=True,
                check=False,
            )
            active = result.stdout.splitlines()
            enabled = len(active) == 2 and all(value == "active" for value in active)
            self.memory_button.setText(
                "Bellek korumasını kapat" if enabled else "Bellek korumasını etkinleştir"
            )
            self.resource_status.setText(
                "ZRAM ve Early OOM etkin."
                if enabled
                else "ZRAM/Early OOM kapalı. Etkinleştirmek bellek baskısını azaltmaya yardımcı olur."
            )
        except OSError as error:
            self.resource_status.setText(f"Servis durumu okunamadı: {error}")

        try:
            profile = subprocess.run(
                ["powerprofilesctl", "get"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip()
            self.cpu_profile_available = True
            self.cpu_button.setText(
                "İşlemci: Dengeli moda dön"
                if profile == "power-saver"
                else "İşlemci: Tasarruf modu"
            )
            self.resource_status.setText(
                self.resource_status.text() + f"  Güç profili: {profile}."
            )
        except (OSError, subprocess.CalledProcessError):
            self.cpu_profile_available = False
            self.set_actions_enabled(self.process is None)
            self.resource_status.setText(
                self.resource_status.text()
                + " Güç profili aracı kullanılamıyor; CPU profili değiştirilemedi."
            )

    def toggle_memory_services(self):
        if "kapalı" in self.resource_status.text().lower():
            action = "memory-on"
        else:
            if QMessageBox.question(
                self,
                "Bellek korumasını kapat",
                "ZRAM ve Early OOM servisleri kapatılacak. Devam edilsin mi?",
                QMessageBox.Yes | QMessageBox.No,
                QMessageBox.No,
            ) != QMessageBox.Yes:
                return
            action = "memory-off"
        self.start_privileged_action(action)

    def toggle_cpu_profile(self):
        button_text = self.cpu_button.text()
        profile = "balanced" if "Dengeli" in button_text else "power-saver"
        try:
            subprocess.run(
                ["powerprofilesctl", "set", profile],
                check=True,
                capture_output=True,
                text=True,
            )
            self.log.setText(f"İşlemci güç profili: {profile}")
            self.refresh_resource_state()
        except (OSError, subprocess.CalledProcessError) as error:
            detail = getattr(error, "stderr", "") or str(error)
            self.log.setText(f"İşlemci profili değiştirilemedi: {detail.strip()}")


if __name__ == "__main__":
    application = QApplication(sys.argv)
    window = MelesGlassCenter()
    window.show()
    sys.exit(application.exec_())
