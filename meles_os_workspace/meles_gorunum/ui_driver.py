#!/usr/bin/env python3
import os, subprocess, time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

subprocess.call(["bash", os.path.join(SCRIPT_DIR, "install_deps.sh")])
subprocess.Popen(["nm-applet"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

subprocess.call(["pkill", "-f", "xfce4-panel"])
time.sleep(0.5)

print("Beyaz Temalı XFCE4 Panel Başlatılıyor...")
subprocess.Popen(["xfce4-panel", "--disable-wm-check"], preexec_fn=os.setpgrp, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
