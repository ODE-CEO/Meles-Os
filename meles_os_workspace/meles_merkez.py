#!/usr/bin/env python3
import configparser
import sys
from pathlib import Path

from PyQt5.QtCore import QProcess
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import (
    QApplication,
    QGridLayout,
    QHBoxLayout,
    QLabel,
    QLineEdit,
    QMainWindow,
    QMessageBox,
    QPushButton,
    QScrollArea,
    QVBoxLayout,
    QWidget,
)


APPLICATIONS_DIR = Path("/usr/share/applications")


class MelesCenter(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Meles Merkez")
        self.resize(900, 680)
        self.setMinimumSize(680, 500)
        self.entries = []

        root = QWidget()
        root.setObjectName("surface")
        self.setCentralWidget(root)
        layout = QVBoxLayout(root)
        layout.setContentsMargins(26, 22, 26, 24)
        layout.setSpacing(14)

        heading = QLabel("MELES MERKEZ")
        heading.setObjectName("heading")
        subtitle = QLabel("Meles uygulamalarına tek yerden erişin")
        subtitle.setObjectName("muted")
        layout.addWidget(heading)
        layout.addWidget(subtitle)

        self.search = QLineEdit()
        self.search.setPlaceholderText("Uygulama ara…")
        self.search.textChanged.connect(self.render_apps)
        layout.addWidget(self.search)

        self.scroll = QScrollArea()
        self.scroll.setWidgetResizable(True)
        self.scroll.setFrameShape(QScrollArea.NoFrame)
        self.app_container = QWidget()
        self.grid = QGridLayout(self.app_container)
        self.grid.setContentsMargins(2, 2, 8, 8)
        self.grid.setSpacing(12)
        self.scroll.setWidget(self.app_container)
        layout.addWidget(self.scroll, 1)

        footer = QHBoxLayout()
        self.status = QLabel("Uygulamalar yükleniyor…")
        self.status.setObjectName("muted")
        refresh = QPushButton("Yenile")
        refresh.clicked.connect(self.load_apps)
        footer.addWidget(self.status, 1)
        footer.addWidget(refresh)
        layout.addLayout(footer)

        self.setStyleSheet(
            """
            QWidget#surface { background:#11151b; color:#f3f6fa; }
            QLabel#heading { color:#fff; font-size:24px; font-weight:700; letter-spacing:2px; }
            QLabel#muted { color:#aab5c2; font-size:12px; }
            QLineEdit {
                background:#1b222c; color:#fff; border:1px solid #394655;
                border-radius:12px; padding:11px 14px; font-size:14px;
            }
            QPushButton {
                background:#202936; color:#fff; border:1px solid #3b4858;
                border-radius:12px; padding:10px 14px;
            }
            QPushButton:hover { background:#2b3848; border-color:#69b9ff; }
            QScrollArea { background:transparent; }
            QPushButton.appCard {
                min-height:94px; text-align:left; font-size:13px;
                font-weight:600; padding:14px;
            }
            """
        )
        self.load_apps()

    def load_apps(self):
        self.entries = []
        for path in sorted(APPLICATIONS_DIR.glob("*.desktop")):
            if not (path.name.startswith("Meles_") or path.name == "Firefox.desktop"):
                continue
            data = configparser.ConfigParser(interpolation=None, strict=False)
            try:
                data.read(path, encoding="utf-8")
                entry = data["Desktop Entry"]
                if entry.getboolean("Hidden", fallback=False) or entry.getboolean(
                    "NoDisplay", fallback=False
                ):
                    continue
                name = entry.get("Name", path.stem)
                comment = entry.get("Comment", "Meles uygulamasını aç")
                icon = entry.get("Icon", "applications-system")
            except (OSError, KeyError, configparser.Error, ValueError):
                continue
            self.entries.append((path.stem, name, comment, icon))
        self.render_apps()

    def render_apps(self):
        while self.grid.count():
            item = self.grid.takeAt(0)
            widget = item.widget()
            if widget:
                widget.deleteLater()

        query = self.search.text().casefold()
        visible = [
            item
            for item in self.entries
            if query in " ".join(item[1:3]).casefold()
        ]
        for index, (desktop_id, name, comment, icon) in enumerate(visible):
            button = QPushButton(f"{name}\n{comment}")
            button.setObjectName("appCard")
            button.setIcon(QIcon.fromTheme(icon))
            button.setIconSize(button.iconSize() * 1.8)
            button.setToolTip(comment)
            button.clicked.connect(
                lambda _checked=False, app_id=desktop_id: self.launch_app(app_id)
            )
            self.grid.addWidget(button, index // 3, index % 3)
        self.status.setText(f"{len(visible)} uygulama")

    def launch_app(self, desktop_id):
        process = QProcess(self)
        if not process.startDetached("gtk-launch", [desktop_id]):
            QMessageBox.warning(
                self,
                "Uygulama açılamadı",
                f"{desktop_id} başlatılamadı. Masaüstü uygulama girdisini kontrol edin.",
            )


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MelesCenter()
    window.show()
    sys.exit(app.exec_())
