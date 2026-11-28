#!/bin/bash
echo "[DEPS] XFCE4 Panel paketleri denetleniyor..."
if ! command -v xfce4-panel &> /dev/null || ! dpkg -l | grep -q xfce4-whiskermenu-plugin; then
    sudo apt-get update -qq
    sudo apt-get install -y xfce4-panel xfce4-whiskermenu-plugin xfce4-settings xfconf network-manager-gnome xfce4-battery-plugin
fi
