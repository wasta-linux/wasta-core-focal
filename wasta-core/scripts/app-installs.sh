#!/bin/bash

# ==============================================================================
# wasta-core: app-installs.sh
#
# 2019-11-24 rik: initial focal script
# 2020-01-24 rik: temporarily removing bloom, removing duplicate entry of
#   python-appindicator
# 2020-02-01 rik: removing nautilus-compare, commenting out keyman ppa logic
#   - removing ice: it pulls in chromium-browser which is only a snap.
#
# ==============================================================================

# ------------------------------------------------------------------------------
# Check to ensure running as root
# ------------------------------------------------------------------------------
#   No fancy "double click" here because normal user should never need to run
if [ $(id -u) -ne 0 ]
then
    echo
    echo "You must run this script with sudo." >&2
    echo "Exiting...."
    sleep 5s
    exit 1
fi

# ------------------------------------------------------------------------------
# Function: aptError
# ------------------------------------------------------------------------------
aptError () {
    if [ "$AUTO" ];
    then
        echo
        echo "*** ERROR: apt-get command failed. You may want to re-run!"
        echo
    else
        echo
        echo "     --------------------------------------------------------"
        echo "     'APT' Error During Update / Installation"
        echo "     --------------------------------------------------------"
        echo
        echo "     An error was encountered with the last 'apt' command."
        echo "     You should close this script and re-start it, or"
        echo "     correct the error manually before proceeding."
        echo
        read -p "     Press any key to proceed..."
        echo
   fi
}

# ------------------------------------------------------------------------------
# Initial Setup
# ------------------------------------------------------------------------------

echo
echo "*** Script Entry: app-installs.sh"
echo
# Setup variables for later reference
DIR=/usr/share/wasta-core
SERIES=$(lsb_release -sc)

# if 'auto' parameter passed, run non-interactively
if [ "$1" == "auto" ];
then
    AUTO="auto"
    
    # needed for apt-get
    YES="--yes"
    DEBIAN_NONINTERACTIVE="env DEBIAN_FRONTEND=noninteractive"

    # needed for gdebi
    INTERACTIVE="-n"

    # needed for dpkg-reconfigure
    DPKG_FRONTEND="--frontend=noninteractive"
else
    AUTO=""
    YES=""
    DEBIAN_NONINTERACTIVE=""
    INTERACTIVE=""
    DPKG_FRONTEND=""
fi

# ------------------------------------------------------------------------------
# Configure sources and update settings and do update
# ------------------------------------------------------------------------------
echo
echo "*** Making adjustments to software repository sources"
echo

APT_SOURCES=/etc/apt/sources.list

if ! [ -e $APT_SOURCES.wasta ];
then
    APT_SOURCES=/etc/apt/sources.list
    APT_SOURCES_D=/etc/apt/sources.list.d
else
    # wasta-offline active: adjust apt file locations
    echo
    echo "*** wasta-offline active, applying repository adjustments to /etc/apt/sources.list.wasta"
    echo
    APT_SOURCES=/etc/apt/sources.list.wasta
    if [ -e /etc/apt/sources.list.d ];
    then
        echo
        echo "*** wasta-offline 'offline and internet' mode detected"
        echo
        # wasta-offline "offline and internet mode": no change to sources.list.d
        APT_SOURCES_D=/etc/apt/sources.list.d
    else
        echo
        echo "*** wasta-offline 'offline only' mode detected"
        echo
        # wasta-offline "offline only mode": change to sources.list.d location
        APT_SOURCES_D=/etc/apt/sources.list.d.wasta
    fi
fi

# first backup $APT_SOURCES in case something goes wrong
# delete $APT_SOURCES.save if older than 30 days
find /etc/apt  -maxdepth 1 -mtime +30 -iwholename $APT_SOURCES.save -exec rm {} \;

if ! [ -e $APT_SOURCES.save ];
then
    cp $APT_SOURCES $APT_SOURCES.save
fi

# Manually add repo keys:
#   - apt-key no longer supported in scripts so need to use gpg directly.
#       - Still works 18.04 but warning it may break in the future: however
#         the direct gpg calls were problematic so keeping same for bionic.
#   - sending output to null to not scare users
apt-key add $DIR/keys/libreoffice-ppa.gpg > /dev/null 2>&1
apt-key add $DIR/keys/keymanapp-ppa.gpg > /dev/null 2>&1
apt-key add $DIR/keys/skype.gpg > /dev/null 2>&1

# add LibreOffice 6.2 PPA
# if ! [ -e $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-6-2-$SERIES.list ];
# then
#     echo
#     echo "*** Adding LibreOffice 6.2 PPA"
#     echo
#     echo "deb http://ppa.launchpad.net/libreoffice/libreoffice-6-2/ubuntu $SERIES main" | \
#         tee $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-6-2-$SERIES.list
#     echo "# deb-src http://ppa.launchpad.net/libreoffice/libreoffice-6-2/ubuntu $SERIES main" | \
#         tee -a $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-6-2-$SERIES.list
# else
#     # found, but ensure LibreOffice PPA ACTIVE (user could have accidentally disabled)
#     # DO NOT match any lines ending in #wasta
#     sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
#        $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-6-2-$SERIES.list
# fi

#echo
#echo "*** Removing Older LibreOffice PPAs"
#echo
#rm -f $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-6-0*
#rm -f $APT_SOURCES_D/libreoffice-ubuntu-libreoffice-6-1*

# Add Skype repository
if ! [ -e $APT_SOURCES_D/skype-stable.list ];
then
    echo
    echo "*** Adding Skype Repository"
    echo

    echo "deb https://repo.skype.com/deb stable main" | \
        tee $APT_SOURCES_D/skype-stable.list
fi

# TODO: Re-enable when keyman focal is available

# add Keyman PPA
#if ! [ -e $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list ];
#then
#    echo
#    echo "*** Adding Keyman PPA"
#    echo
#    echo "deb http://ppa.launchpad.net/keymanapp/keyman/ubuntu $SERIES main" | \
#        tee $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list
#    echo "# deb-src http://ppa.launchpad.net/keymanapp/keyman/ubuntu $SERIES main" | \
#        tee -a $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list
# else
#     # found, but ensure Keyman PPA ACTIVE (user could have accidentally disabled)
#     # DO NOT match any lines ending in #wasta
#     sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
#        $APT_SOURCES_D/keymanapp-ubuntu-keyman-$SERIES.list
#fi

# 2017-11-29 rik: NOTE: pfsense caching will NOT work with this no-cache option
#   set to True.  So disabling for bionic for now until get more input from
#   other users (but Ethiopia for example will want this set to False)
#if ! [ -e /etc/apt/apt.conf.d/99nocache ];
#then
#    echo 'Acquire::http::No-Cache "True";' > /etc/apt/apt.conf.d/99nocache
#fi

apt-get update

    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        aptError
    fi

# ------------------------------------------------------------------------------
# Upgrade ALL
# ------------------------------------------------------------------------------

echo
echo "*** Install All Updates"
echo

$DEBIAN_NONINERACTIVE apt-get $YES dist-upgrade

    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        aptError
    fi

# ------------------------------------------------------------------------------
# Standard package installs for all systems
# -----------------------------------------ri-------------------------------------

echo
echo "*** Standard Installs"
echo

# adobe-flashplugin: flash
# aisleriot: solitare game
# android-tools-adb: terminal - communicate to Android devices
# apt-rdepends: reverse dependency lookup
# audacity lame: audio editing
# bloom-desktop art-of-reading3: sil bloom
# bookletimposer: pdf booklet / imposition tool
# brasero: CD/DVD burner
# catfish: more in-depth search than nemo gives (gnome-search-tool not available)
# cheese: webcam recorder, picture taker
# cifs-utils: "common internet filesystem utils" for fileshare utilities, etc.
# curl: terminal - download utility
# dconf-cli, dconf-editor: gives tools for making settings adjustments
# debconf-utils: needed for debconf-get-selections, etc. for debconf configure
# diodon: clipboard manager
# dos2unix: terminal - convert line endings of files to / from windows to unix
# easytag: GUI ID3 tag editor
# exfat-fuse, exfat-utils: compatibility for exfat formatted disks
# extundelete: terminal - restore deleted files
# fbreader: e-book reader
# font-manager: GUI for managing fonts
# fonts-crosextra-caladea: metrically compatible with "Cambria"
# fonts-crosextra-carlito: metrically compatible with "Calibri"
# fonts-sil-*: standard SIL fonts
# gcolor3: color pickerg
# gddrescue: data recovery tool
# gdebi: graphical .deb installer
# gimp: advanced graphics editor
# git: terminal - command-line git
# goldendict: more advanced dictionary/thesaurus tool than artha
# gnome-calculator
# gnome-clocks: multi-timezone clocks, timers, alarms
# gnome-font-viewer: better than "font-manager" for just viewing a font file.
# gnome-logs: GUI log viewer
# gnome-maps: GUI map viewer
# gnome-nettool: network tool GUI (traceroute, lookup, etc)
# gnome-system-monitor:
# gparted: partition manager
# grsync: GUI rsync tool
# gucharmap: gnome character map (traditional)
# gufw: GUI for "uncomplicated firewall"
# hardinfo: system profiler
# hddtemp: terminal - harddrive temp checker
# hfsprogs: for apple hfs compatiblity
# htop: process browser
# httrack: website download utility
# imagemagick: terminal - image resizing, etc. (needed for nemo resize action)
# inkscape: vector graphics editor
# inotify-tools: terminal - watch for file changes
# iperf: terminal - network bandwidth measuring
# kdenlive: video editor
# keepassxc: password manager (xc is the community port that is more up to date)
# keyman: keyman keyboard app
# klavaro: typing tutor
# kmfl-keyboard-ipa: ipa keyboard for kmfl
# libdvd-pkg: enables DVD playback (downloads and installs libdvdcss2)
# libreoffice: install the full meta-package
# libreoffice-sdbc-hsqldb: (pre-firebird) db backend for LO base
# libtext-pdf-perl: provides pdfbklt (make A5 booklet from pdf)
# TODO: nautilus-compare not available for focal
# meld nautilus-compare: graphical text file compare utility
# mkusb-nox: teminal usb creator (15.10 issue with usb-creator-gtk)
# modem-manager-gui: Check balance, top up, check signal strength, etc.
# mtp-tools: media-transfer-protocol tools: needed for smartphones
# myspell-en-gb: spell checker for English (UK): needed for Libre Office
# nautilus-compare: nautilus integration with meld
# ncdu: terminal - ncurses disk usage analyzer tool
# nethogs: CLI network monitor showing per application net usage
# net-tools: terminal - basic utilities like ifconfig
# pandoc: terminal - general markup converter
# papirus-icon-theme:
# pinta: MS Paint alternative: more simple for new users than gimp
# qt5-style-plugins: needed for qt5 / gtk theme compatibility
# redshift-gtk: redshift for blue light reduction
# rhythmbox: music manager
# shotwell: photo editor / manager (can edit single files easily)
# silcc: terminal - SIL consistent changes
# simplescreenrecorder: screen recorder 
# skypeforlinux: skype
# soundconverter: convert audio formats
# sound-juicer: rip CDs
# ssh: terminal - remote access
# synaptic: more advanced package manager
#   - apt-xapian-index: for synpatic indexing
# sysstat: terminal - provides sar: system activity reporter
# teckit: terminal - SIL teckit
# testdisk: terminal - photorec tool for recovery of deleted files
# thunderbird xul-ext-lightning: GUI email client
# tldr: terminal - gives 'tldr' summary of manpages
# tlp: laptop power savings
# traceroute: terminal
# ttf-mscorefonts-installer: installs standard Microsoft fonts
# ubiquity-frontend-gtk: add here so not needed to be downloaded by
#   wasta-remastersys or if needs to be updated by app-adjustments.sh
# ubiquity-slideshow-wasta:
# ubuntu-software: not great but currently no better option
# ubuntu-restricted-extras: mp3, flash, etc.
# ubuntu-wallpapers-*: wallpaper collections
# uget uget-integrator: GUI download manager (DTA in Firefox abandoned)
# vim-tiny: terminal - text editor (don't want FULL vim or else in main menu)
# vlc: play any audio or video files
# wasta-backup: GUI for rdiff-backup
# wasta-ibus-bionic: wasta customization of ibus
# wasta-menus: applicationmenu limiting system
# wasta-offline wasta-offline-setup: offline updates and installs
# wasta-papirus papirus-icon-theme: more 'modern' icon theme
# wasta-remastersys: create ISO of system
# wasta-resources-core: wasta-core documentation and resources
# wavemon: terminal - for wireless network diagonstics
# xmlstarlet: terminal - reading / writing to xml files
# xsltproc: terminal - xslt, xml conversion program
# xul-ext-lightning: Thunderbird Lightning (calendar) Extension
# youtube-dl: terminal - youtube / video downloads
# zim, python-appindicator: wiki style note taking app - appindicator needed
#   for tray icon

$DEBIAN_NONINERACTIVE bash -c "apt-get $YES install \
    adobe-flashplugin \
    aisleriot \
    android-tools-adb \
    apt-rdepends \
    apt-xapian-index \
    audacity lame \
    bookletimposer \
    brasero \
    catfish \
    cheese \
    cifs-utils \
    curl \
    dconf-cli \
        dconf-editor \
    debconf-utils \
    diodon \
    dos2unix \
    easytag \
    exfat-fuse \
        exfat-utils \
    extundelete \
    fbreader \
    font-manager \
    fonts-crosextra-caladea \
    fonts-crosextra-carlito \
    fonts-sil-andika \
        fonts-sil-andika-compact \
        fonts-sil-annapurna \
        fonts-sil-charis \
        fonts-sil-charis-compact \
        fonts-sil-doulos \
        fonts-sil-doulos-compact \
        fonts-sil-gentiumplus \
        fonts-sil-gentiumplus-compact \
    gcolor3 \
    gddrescue \
    gdebi \
    gimp \
    git \
    goldendict \
        goldendict-wordnet \
    gnome-calculator \
    gnome-clocks \
    gnome-font-viewer \
    gnome-logs \
    gnome-maps \
    gnome-nettool \
    gnome-screenshot \
    gnome-system-monitor \
    gparted \
    grsync \
    gucharmap \
    gufw \
    hardinfo \
    hddtemp \
    hfsprogs \
    htop \
    httrack \
    imagemagick \
    inkscape \
    inotify-tools \
    iperf \
    kdenlive \
    keepassxc \
    keyman \
    klavaro \
    kmfl-keyboard-ipa \
    libdvd-pkg \
    libreoffice \
        libreoffice-sdbc-hsqldb \
    libtext-pdf-perl \
    meld \
    mkusb-nox \
    modem-manager-gui \
    mtp-tools \
    ncdu \
    nethogs \
    net-tools \
    pandoc \
    papirus-icon-theme \
    pinta \
    qt5-style-plugins \
    redshift-gtk \
    rhythmbox \
    shotwell \
    silcc \
    simplescreenrecorder \
    skypeforlinux \
    soundconverter \
    sound-juicer \
    ssh \
    sysstat \
    synaptic apt-xapian-index \
    teckit \
    testdisk \
    thunderbird xul-ext-lightning \
    tldr \
    tlp \
    traceroute \
    ttf-mscorefonts-installer \
    ubiquity-frontend-gtk \
    ubiquity-slideshow-wasta \
    ubuntu-software \
    ubuntu-restricted-extras \
    uget uget-integrator \
    vim-tiny \
    vlc \
    wasta-backup \
    wasta-ibus-focal \
    wasta-menus \
    wasta-offline wasta-offline-setup \
    wasta-papirus papirus-icon-theme \
    wasta-remastersys \
    wasta-resources-core \
    wavemon \
    xmlstarlet \
    xsltproc \
    youtube-dl \
    zim \
    "

    LASTERRORLEVEL=$?
    if [ "$LASTERRORLEVEL" -ne "0" ];
    then
        aptError
    fi

# ------------------------------------------------------------------------------
# Language Support Files: install
# -----------------------------------------------------------------------------
echo
echo "*** Installing Language Support Files"
echo

SYSTEM_LANG=$(locale | grep LANG= | cut -d= -f2 | cut -d_ -f1)
INSTALL_APPS=$(check-language-support -l $SYSTEM_LANG)

apt-get $YES install $INSTALL_APPS

# ------------------------------------------------------------------------------
# wasta-remastersys conf updates
# ------------------------------------------------------------------------------
WASTA_REMASTERSYS_CONF=/etc/wasta-remastersys/wasta-remastersys.conf
if [ -e "$WASTA_REMASTERSYS_CONF" ];
then
    # change to wasta-linux splash screen
    sed -i -e 's@SPLASHPNG=.*@SPLASHPNG="/usr/share/wasta-core/resources/wasta-linux-vga.png"@' \
        "$WASTA_REMASTERSYS_CONF"
    
    # set default CD Label and ISO name
    WASTA_ID="$(sed -n "\@^ID=@s@^ID=@@p" /etc/wasta-release)"
    WASTA_VERSION="$(sed -n "\@^VERSION=@s@^VERSION=@@p" /etc/wasta-release)"
    ARCH=$(uname -m)
    if [ $ARCH == 'x86_64' ];
    then
        WASTA_ARCH="64bit"
    else
        WASTA_ARCH="32bit"
    fi
    WASTA_DATE=$(date +%F)

    #shortening CUSTOMISO since if it is too long wasta-remastersys will fail
    sed -i -e "s@LIVECDLABEL=.*@LIVECDLABEL=\"$WASTA_ID $WASTA_VERSION $WASTA_ARCH\"@" \
           -e "s@CUSTOMISO=.*@CUSTOMISO=\"WL-$WASTA_VERSION-$WASTA_ARCH.iso\"@" \
           -e "s@SLIDESHOW=.*@SLIDESHOW=wasta@" \
        "$WASTA_REMASTERSYS_CONF"
fi

# ------------------------------------------------------------------------------
# Reconfigure libdvd-pkg to get libdvdcss2 installed
# ------------------------------------------------------------------------------
# during the install of libdvd-pkg it can't in turn install libdvdcss2 since
#   another dpkg process is already active, so need to do it again
dpkg-reconfigure $DPKG_FRONTEND libdvd-pkg

# ------------------------------------------------------------------------------
# Clean up apt cache
# ------------------------------------------------------------------------------
# not doing since we may want those packages for wasta-offline
#apt-get autoremove
#apt-get autoclean

echo
echo "*** Script Exit: app-installs.sh"
echo

exit 0
