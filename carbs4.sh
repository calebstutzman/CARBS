#!/bin/sh

initialcheck() { pacman -S --noconfirm --needed dialog || { echo "Are you  sure you're running this as the root user? Are you sure you have an internet connection?"; exit; } ;}

preinstallmsg() { dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind." --yesno "The rest of the installation will now be fully automated.\n\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
}

refreshkeys() { dialog --infobox "Refreshing Arch Keyring..." 4 40
		pacman --noconfirm -Sy archlinux-keyring &>/dev/null
}

maininstall() { dialog --title "CARBS Installation" --infobox "Installing programs." 5 70
pacman --noconfirm --needed -S vim git firefox i3-gaps i3blocks ranger compton dunst base-devel pulseaudio pulseaudio-alsa pamixer scrot ttf-inconsolata ttf-linux-libertine w3m unzip unrar wget rxvt-unicode
}

putgitrepo() { dialog --infobox "Downloading and installing dotfiles..." 4 60 
git clone https://github.com/calebstutzman/archrice /home/caleb
cp -r /home/caleb/archrice/.config /home/caleb/

finalize(){ \
        dialog --infobox "Preparing welcome message..." 4 50
        dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\n\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment.\n\n-Caleb" 12 80
        }


###
### FUNCTIONS ###
###

initialcheck

preinstallmsg

refreshkeys

maininstall

putgitrepo

finalize

