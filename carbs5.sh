#!/bin/sh 

pacman -Syyu

pacman --noconfirm -Sy archlinux-keyring &>/dev/null

pacman --noconfirm --needed -S vim git firefox i3-gaps i3blocks ranger compton dunst base-devel pulseaudio pulseaudio-alsa pamixer scrot ttf-inconsolata unzip rxvt-unicode git

sudo -u caleb packer -S --noconfirm ttf-emojione gitkraken

git clone https://github.com/calebstutzman/archrice/ /home/caleb/

cp -r /home/caleb/archrice/.config /home/caleb/
 
 

