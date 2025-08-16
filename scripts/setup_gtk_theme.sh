#!/bin/bash

sudo mkdir -p /usr/share/themes
sudo git clone https://github.com/afkale/dracula-gtk /usr/share/themes/Dracula

gsettings set org.gnome.desktop.interface gtk-theme "Dracula"
gsettings set org.gnome.desktop.wm.preferences theme "Dracula"
gsettings set org.gnome.desktop.interface icon-theme "Dracula"
