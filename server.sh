#!/usr/bin/env bash

sudo add-apt-repository ppa:fish-shell/release-4
sudo apt update && sudo apt upgrade

sudo apt install nala 
sudo nala install fish -y

chsh -s "$(which fish)"

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --no-bash --no-zsh


# LONGHORN
sudo nala install open-iscsi nfs-common cryptsetup -y
sudo systemctl enable iscsid --now
sudo systemctl status iscsid
# LONGHORN

MAC=$(printf 'DE:%02X:%02X:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

IFACE=$(ip link show | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2; getline}' | tr -d ' ' | head -1)

echo "Interface: $IFACE"
echo "New MAC:   $MAC"

sudo tee /etc/systemd/network/10-mac.link > /dev/null <<EOF
[Match]
OriginalName=$IFACE

[Link]
MACAddress=$MAC
EOF

cat <<'EOF' > "$HOME/.config/fish/config.fish"
status is-login; and begin
end
set fish_greeting

fish_vi_key_bindings

set -Ux EDITOR nvim

if status is-interactive
  fzf --fish | source
end
EOF

fish -c "echo 'Hello world!'"
fish -c "set -Ux FZF_DEFAULT_OPTS '
  --reverse
  --color=bg+:#313244,bg:,spinner:#F5E0DC,hl:#F38BA8
  --color=fg:#CDD6F4,header:#F38BA8,info:#CBA6F7,pointer:#F5E0DC
  --color=marker:#B4BEFE,fg+:#CDD6F4,prompt:#CBA6F7,hl+:#F38BA8
  --color=selected-bg:#45475A
  --color=border:#6C7086,label:#CDD6F4'"


sudo lvcreate -n longhorn-lv -l 100%FREE ubuntu-vg
sudo mkfs.ext4 /dev/ubuntu-vg/longhorn-lv
sudo mkdir -p /var/lib/longhorn

sudo blkid /dev/ubuntu-vg/longhorn-lv

echo 'UUID=ae716363-0b72-4d21-a932-542b4f3790ea /var/lib/longhorn ext4 defaults 0 2' | sudo tee -a /etc/fstab
sudo mount -a
df -h /var/lib/longhorn


curl -sfL https://get.k3s.io | K3S_URL=https://192.168.0.120:6443 \
  K3S_TOKEN=K107e569f79c1623b6745225efde343abfe98dc444f228027cd780b7c516850ba74::server:25116e67dbc757fdd05630776e1ba8f3 sh -s - \
  --node-name nod01 \
  --flannel-iface enp0s31f6
