#!/usr/bin/env python3
import sys

from PyQt5.QtCore import QProcess
from PyQt5.QtGui import QTextCursor
from PyQt5.QtWidgets import (
    QApplication,
    QFrame,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QPlainTextEdit,
    QProgressBar,
    QVBoxLayout,
    QWidget,
)


class RepairWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Meles Sistem Onarımı")
        self.resize(800, 650)
        self.setMinimumSize(640, 520)
        self.process = None
        self.diagnostics_process = None

        root = QWidget()
        root.setObjectName("surface")
        self.setCentralWidget(root)
        layout = QVBoxLayout(root)
        layout.setContentsMargins(26, 22, 26, 24)
        layout.setSpacing(14)

        title = QLabel("SİSTEM ONARIMI")
        title.setObjectName("heading")
        intro = QLabel(
            "Paket sorunlarını giderin, açılış dosyalarını yenileyin veya donanım tanılamasını açın."
        )
        intro.setObjectName("muted")
        intro.setWordWrap(True)
        layout.addWidget(title)
        layout.addWidget(intro)

        cards = QHBoxLayout()
        cards.setSpacing(12)
        self.add_action(
            cards,
            "Paketleri onar",
            "Bekleyen paket yapılandırmasını ve bağımlılık hatalarını düzeltir.",
            "packages",
        )
        self.add_action(
            cards,
            "Önyüklemeyi onar",
            "initramfs ve GRUB yapılandırmasını yeniden oluşturur.",
            "boot",
        )
        self.add_action(
            cards,
            "Sürücü ve donanım",
            "Sürücü durumunu ve sistem kaynaklarını görüntüler.",
            "drivers",
        )
        layout.addLayout(cards)

        self.progress = QProgressBar()
        self.progress.setRange(0, 0)
        self.progress.hide()
        layout.addWidget(self.progress)
        self.log = QPlainTextEdit()
        self.log.setReadOnly(True)
        self.log.setPlaceholderText("İşlem çıktısı ve tanılama bilgileri burada görünür.")
        layout.addWidget(self.log, 1)
        self.status = QLabel("Hazır")
        self.status.setObjectName("muted")
        layout.addWidget(self.status)

        self.setStyleSheet(
            """
            QWidget#surface { background:#11151b; color:#f3f6fa; }
            QLabel#heading { color:#fff; font-size:23px; font-weight:700; letter-spacing:1px; }
            QLabel#muted { color:#aab5c2; font-size:12px; }
            QFrame#card {
                background:#1b222c; border:1px solid #394655; border-radius:14px;
            }
            QLabel#cardTitle { color:#fff; font-size:15px; font-weight:700; }
            QPushButton {
                background:#202936; color:#fff; border:1px solid #3b4858;
                border-radius:10px; padding:10px 12px; font-weight:600;
            }
            QPushButton:hover { background:#2b3848; border-color:#69b9ff; }
            QPushButton:disabled { color:#738091; }
            QPlainTextEdit {
                background:#0b0e13; color:#d5e0ec; border:1px solid #303b48;
                border-radius:12px; padding:10px; font-family:monospace;
            }
            QProgressBar { max-height:5px; border:0; background:#28313c; }
            QProgressBar::chunk { background:#49a9ff; }
            """
        )
        self.load_diagnostics()

    def add_action(self, row, title, description, action):
        card = QFrame()
        card.setObjectName("card")
        layout = QVBoxLayout(card)
        heading = QLabel(title)
        heading.setObjectName("cardTitle")
        detail = QLabel(description)
        detail.setObjectName("muted")
        detail.setWordWrap(True)
        button = QPushButton("Aç / Başlat")
        button.clicked.connect(lambda _checked=False, task=action: self.run_action(task))
        layout.addWidget(heading)
        layout.addWidget(detail, 1)
        layout.addWidget(button)
        row.addWidget(card, 1)

    def load_diagnostics(self):
        self.log.setPlainText("Sistem bilgileri okunuyor…")
        self.diagnostics_process = QProcess(self)
        self.diagnostics_process.finished.connect(self.show_diagnostics)
        self.diagnostics_process.start(
            "/bin/bash",
            [
                "-c",
                "printf 'Bellek\\n'; free -h; printf '\\nDisk\\n'; "
                "df -h -x tmpfs -x devtmpfs; printf '\\nEn çok kaynak kullananlar\\n'; "
                "ps -eo pid,comm,rss,%cpu --sort=-rss | head -n 8",
            ],
        )

    def show_diagnostics(self, _code, _status):
        process = self.diagnostics_process
        if process is None:
            return
        output = bytes(process.readAllStandardOutput()).decode(errors="replace")
        self.log.setPlainText(output or "Tanılama bilgisi alınamadı.")
        self.diagnostics_process = None
        process.deleteLater()

    def run_action(self, action):
        if self.process is not None:
            return
        if action == "drivers":
            process = QProcess(self)
            if not process.startDetached(
                "python3", ["/usr/local/bin/meles_glass_center.py"]
            ):
                QMessageBox.warning(self, "Açılamadı", "Donanım merkezi başlatılamadı.")
            return

        description = (
            "Paket yapılandırması ve APT bağımlılık onarımı çalıştırılacak."
            if action == "packages"
            else "initramfs ve GRUB yapılandırması yenilenecek."
        )
        if QMessageBox.question(
            self,
            "Onarımı onayla",
            description + "\nDevam edilsin mi?",
            QMessageBox.Yes | QMessageBox.No,
            QMessageBox.No,
        ) != QMessageBox.Yes:
            return

        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.read_output)
        self.process.readyReadStandardError.connect(self.read_output)
        self.process.finished.connect(self.finish_action)
        self.process.errorOccurred.connect(self.process_error)
        self.set_busy(True)
        self.status.setText("Yönetici onayı bekleniyor…")
        self.process.start(
            "pkexec",
            ["/usr/local/bin/meles-sistem-onarim.sh", "--run", action],
        )

    def read_output(self):
        if self.process is None:
            return
        output = bytes(self.process.readAllStandardOutput()).decode(errors="replace")
        errors = bytes(self.process.readAllStandardError()).decode(errors="replace")
        text = output + errors
        if text:
            self.log.moveCursor(QTextCursor.End)
            self.log.insertPlainText(text)

    def finish_action(self, code, _status):
        self.read_output()
        self.process = None
        self.set_busy(False)
        self.status.setText("Onarım tamamlandı." if code == 0 else f"Onarım başarısız (kod {code}).")
        if code == 0:
            QMessageBox.information(self, "Tamamlandı", "Onarım işlemi tamamlandı.")

    def process_error(self, _error):
        if self.process is None:
            return
        detail = self.process.errorString()
        self.process = None
        self.set_busy(False)
        self.status.setText(f"Onarım başlatılamadı: {detail}")

    def set_busy(self, busy):
        self.progress.setVisible(busy)
        self.status.setEnabled(True)
        for button in self.findChildren(QPushButton):
            button.setEnabled(not busy)

    def closeEvent(self, event):
        for process in (self.process, self.diagnostics_process):
            if process is not None and process.state() != QProcess.NotRunning:
                process.kill()
                process.waitForFinished(1000)
        super().closeEvent(event)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = RepairWindow()
    window.show()
    sys.exit(app.exec_())
