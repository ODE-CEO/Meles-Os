#!/usr/bin/env python3
import sys, os, subprocess
from PyQt5.QtCore import *
from PyQt5.QtWidgets import *
from PyQt5.QtGui import *

class MelesAIAgent(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Meles AI")
        self.resize(600, 500)
        self.setStyleSheet("background-color: #1a1e24; color: white; font-family: 'Segoe UI', sans-serif;")
        self.center()
        
        self.central = QWidget()
        self.setCentralWidget(self.central)
        self.layout = QVBoxLayout(self.central)
        self.layout.setContentsMargins(20, 20, 20, 20)
        
        self.check_ollama()

    def center(self):
        qr = self.frameGeometry()
        cp = QApplication.primaryScreen().geometry().center()
        qr.moveCenter(cp)
        self.move(qr.topLeft())

    def check_ollama(self):
        try:
            res = subprocess.run(["which", "ollama"], capture_output=True, text=True)
            if res.stdout.strip():
                self.init_chat_ui()
            else:
                self.init_install_ui()
        except:
            self.init_install_ui()

    def init_install_ui(self):
        self.clear_layout()
        lbl = QLabel("<h2>Ollama Motoru Bulunamadı!</h2><p>Yapay Zeka modülünün çalışması için Ollama gereklidir.</p>")
        lbl.setAlignment(Qt.AlignCenter)
        self.layout.addWidget(lbl)
        
        btn_light = QPushButton("Hafif Model Kur (gemma2:2b)")
        btn_light.setStyleSheet("background-color: #0078D7; padding: 15px; border-radius: 8px; font-weight: bold;")
        btn_light.clicked.connect(lambda: self.start_install("gemma2:2b"))
        
        btn_heavy = QPushButton("Ağır Model Kur (llama3.2)")
        btn_heavy.setStyleSheet("background-color: #872ec4; padding: 15px; border-radius: 8px; font-weight: bold;")
        btn_heavy.clicked.connect(lambda: self.start_install("llama3.2"))
        
        self.layout.addWidget(btn_light)
        self.layout.addWidget(btn_heavy)

    def start_install(self, model):
        cmd = f"curl -fsSL https://ollama.com/install.sh | sh && ollama run {model}"
        subprocess.Popen(f"gnome-terminal -- bash -c '{cmd}'", shell=True)
        QMessageBox.information(self, "Kurulum", "Terminal açıldı. Kurulum bittikten sonra bu pencereyi kapatıp Meles AI'ı tekrar açın.")
        self.close()

    def init_chat_ui(self):
        self.clear_layout()
        
        self.chat_area = QTextBrowser()
        self.chat_area.setStyleSheet("background-color: #12151a; border-radius: 10px; padding: 10px; font-size: 14px;")
        self.chat_area.append("<b>[Sistem]:</b> Meles AI Ajanı Aktif. 'aç tarayıcı' veya 'dosya oluştur test.txt' yazabilirsiniz.")
        self.layout.addWidget(self.chat_area)
        
        input_layout = QHBoxLayout()
        self.input_field = QLineEdit()
        self.input_field.setStyleSheet("background-color: #2b323c; border-radius: 8px; padding: 10px; font-size: 14px;")
        self.input_field.returnPressed.connect(self.process_command)
        
        btn_send = QPushButton("Gönder")
        btn_send.setStyleSheet("background-color: #0078D7; border-radius: 8px; padding: 10px 20px; font-weight: bold;")
        btn_send.clicked.connect(self.process_command)
        
        input_layout.addWidget(self.input_field)
        input_layout.addWidget(btn_send)
        self.layout.addLayout(input_layout)
        
        watermark = QLabel("Ollama ile Geliştirilmiştir")
        watermark.setStyleSheet("color: rgba(255,255,255,0.4); font-size: 10px; font-weight: bold;")
        watermark.setAlignment(Qt.AlignRight)
        self.layout.addWidget(watermark)

    def process_command(self):
        text = self.input_field.text().strip()
        if not text: return
        self.chat_area.append(f"<b style='color:#00BFFF;'>Sen:</b> {text}")
        self.input_field.clear()
        
        t = text.lower()
        if t.startswith("aç "):
            uyg = t.replace("aç ", "").strip()
            self.chat_area.append(f"<b>[Ajan]:</b> {uyg} açılıyor...")
            os.system(f"{uyg} &")
        elif t.startswith("dosya oluştur "):
            parts = text.split(" ")
            if len(parts) >= 3:
                fname = parts[2]
                with open(os.path.expanduser(f"~/{fname}"), "w") as f:
                    f.write("Meles AI tarafindan olusturuldu.")
                self.chat_area.append(f"<b>[Ajan]:</b> {fname} oluşturuldu.")
        else:
            self.chat_area.append("<b>[Ajan]:</b> Düşünülüyor...")
            QApplication.processEvents()
            try:
                p = subprocess.run(["ollama", "run", "gemma2:2b", text], capture_output=True, text=True)
                resp = p.stdout.strip()
                if not resp: resp = "Üzgünüm, yanıt gelmedi."
                self.chat_area.append(f"<b>[Ajan]:</b> {resp}")
            except Exception as e:
                self.chat_area.append(f"<b>[Ajan]:</b> Hata: {e}")

    def clear_layout(self):
        for i in reversed(range(self.layout.count())): 
            w = self.layout.itemAt(i).widget()
            if w: w.deleteLater()

if __name__ == '__main__':
    app = QApplication(sys.argv)
    win = MelesAIAgent()
    win.show()
    sys.exit(app.exec_())
