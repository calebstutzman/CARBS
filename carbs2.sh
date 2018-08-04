#!/bin/sh

### DEPENDENCIES: git and make . Make sure these are either in the progs.csv file or installed beforehand.

###
### OPTIONS AND VARIABLES ###
###

while getopts ":a:r:p:h" o; do case "${o}" in
        h) echo -e "Optional arguments for custom use:\n  -r: Dotfiles repository (local file or url)\n  -p: Dependencies and programs csv (local file or url)\n  -a: AUR helper (must have pacman-like syntax)\n  -h: Show this message" && exit ;;
        r) dotfilesrepo=${OPTARG} && git ls-remote $dotfilesrepo || exit ;;
        p) progsfile=${OPTARG} ;;
        a) aurhelper=${OPTARG} ;;
        *) echo "-$OPTARG is not a valid option." && exit ;;
esac done

# DEFAULTS:
[ -z ${dotfilesrepo+x} ] && dotfilesrepo="https://github.com/calebstutzman/archrice.git"
[ -z ${progsfile+x} ] && progsfile="https://raw.githubusercontent.com/calebstutzman/archrice/master/progs.csv"
[ -z ${aurhelper+x} ] && aurhelper="packer"

###
### FUNCTIONS ###
###


initialcheck() { pacman -S --noconfirm --needed dialog || { echo "Are you sure you're running this as the root user? Are you sure you're using an Arch-based distro? ;-) Are you sure you have an internet connection?"; exit; } ;}

preinstallmsg() { \
        dialog --title "Let's get this party started!" --yes-label "Let's go!" --no-label "No, nevermind!" --yesno "The rest of the installation will now be totally automated, so you can sit back and relax.\n\nIt will take some time, but when done, you can relax even more with your complete system.\n\nNow just press <Let's go!> and the system will begin installation!" 13 60 || { clear; exit; }
        }

welcomemsg() { \
        dialog --title "Welcome!" --msgbox "Welcome to Caleb's Auto-Rice Bootstrapping Script!\n\nThis script will automatically install a fully-featured i3wm Arch Linux desktop.\n\n-Caleb" 10 60
        }

refreshkeys() { \
        dialog --infobox "Refreshing Arch Keyring..." 4 40
        pacman --noconfirm -Sy archlinux-keyring &>/dev/null
        }

gitmakeinstall() {
        dir=$(mktemp -d)
        dialog --title "CARBS Installation" --infobox "Installing \`$(basename $1)\` ($n of $total) via \`git\` and \`make\`. $(basename $1) $2." 5 70
        git clone --depth 1 "$1" $dir &>/dev/null
        cd $dir
        make &>/dev/null
        make install &>/dev/null
        cd /tmp ;}

maininstall() { # Installs all needed programs from main repo.
        dialog --title "CARBS Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2." 5 70
        pacman --noconfirm --needed -S "$1" &>/dev/null
        }

aurinstall() { \
        dialog --title "CARBS Installation" --infobox "Installing \`$1\` ($n of $total) from the AUR. $1 $2." 5 70
        grep "^$1$" <<< "$aurinstalled" && return
        sudo -u $name $aurhelper -S --noconfirm "$1" &>/dev/null
        }

installationloop() { \
        ([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" > /tmp/progs.csv
        total=$(wc -l < /tmp/progs.csv)
        aurinstalled=$(pacman -Qm | awk '{print $1}')
        while IFS=, read -r tag program comment; do
        n=$((n+1))
        case "$tag" in
        "") maininstall "$program" "$comment" ;;
        "A") aurinstall "$program" "$comment" ;;
        "G") gitmakeinstall "$program" "$comment" ;;
        esac
        done < /tmp/progs.csv ;}

putgitrepo() { # Downlods a gitrepo $1 and places the files in $2 only overwriting conflicts
        dialog --infobox "Downloading and installing config files..." 4 60
        dir=$(mktemp -d)
        chown -R $name:wheel $dir
        sudo -u $name git clone --depth 1 $1 $dir/gitrepo &>/dev/null &&
        sudo -u $name mkdir -p "$2" &&
        sudo -u $name cp -rT $dir/gitrepo $2
        }

resetpulse() { dialog --infobox "Reseting Pulseaudio..." 4 50
        killall pulseaudio &&
        sudo -n $name pulseaudio --start ;}

manualinstall() { # Installs $1 manually if not installed. Used only for AUR helper here.
        [[ -f /usr/bin/$1 ]] || (
        dialog --infobox "Installing \"$1\", an AUR helper..." 10 60
        cd /tmp
        rm -rf /tmp/$1*
        curl -sO https://aur.archlinux.org/cgit/aur.git/snapshot/$1.tar.gz &&
        sudo -u $name tar -xvf $1.tar.gz &>/dev/null &&
        cd $1 &&
        sudo -u $name makepkg --noconfirm -si &>/dev/null
        cd /tmp) ;}

finalize(){ \
        dialog --infobox "Preparing welcome message..." 4 50
        dialog --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place.\n\nTo run the new graphical environment, log out and log back in as your new user, then run the command \"startx\" to start the graphical environment.\n\n-Caleb" 12 80
        }

# Check if user is root on Arch distro. Install dialog.
initialcheck

# Welcome user.
welcomemsg || { clear; exit; }

# Get and verify username and password.
getuserandpass

# Last chance for user to back out before install.
preinstallmsg || { clear; exit; }

# Refresh Arch keyrings.
refreshkeys

manualinstall $aurhelper

# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required. Be sure to run this only after
# the user has been created and has priviledges to run sudo without a password
# and all build dependencies are installed.
installationloop

# Install the dotfiles in the user's home directory
putgitrepo "$dotfilesrepo" "/home/$name"

# Pulseaudio, if/when initially installed, often needs a restart to work immediately.
[[ -f /usr/bin/pulseaudio ]] && resetpulse

# Last message! Install complete!
finalize
clear

