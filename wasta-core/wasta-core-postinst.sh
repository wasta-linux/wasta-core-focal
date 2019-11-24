#!/bin/bash

# ==============================================================================
# wasta-core: wasta-core-postinst.sh
#
#   This script is automatically run by the postinst configure step on
#       installation of wasta-core-xenial.  It can be manually re-run, but is
#       only intended to be run at package installation.
#
#   2019-11-24 rik: initial focal script
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
# Initial Setup
# ------------------------------------------------------------------------------

echo
echo "*** Script Entry: wasta-core-postinst.sh"
echo

# Setup Directory for later reference
DIR=/usr/share/wasta-core

SERIES=$(lsb_release -sc)

# ------------------------------------------------------------------------------
# Configure sources and apt settings
# ------------------------------------------------------------------------------
echo
echo "*** Making adjustments to software repository sources"
echo

APT_SOURCES=/etc/apt/sources.list

if ! [ -e $APT_SOURCES.wasta ];
then
    APT_SOURCES_D=/etc/apt/sources.list.d
else
    # wasta-offline active: adjust apt file locations
    echo
    echo "*** wasta-offline active, applying repository adjustments to /etc/apt/sources.list.wasta"
    echo
    APT_SOURCES=/etc/apt/sources.list.wasta
    if [ "$(ls -A /etc/apt/sources.list.d)" ];
    then
        echo
        echo "*** wasta-offline 'offline and internet' mode detected"
        echo
        # files inside /etc/apt/sources.list.d so it is active
        # wasta-offline "offline and internet mode": no change to sources.list.d
        APT_SOURCES_D=/etc/apt/sources.list.d
    else
        echo
        echo "*** wasta-offline 'offline only' mode detected"
        echo
        # no files inside /etc/apt/sources.list.d
        # wasta-offline "offline only mode": change to sources.list.d.wasta
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

# ensure all ubuntu repositories enabled (will ensure not commented out)
# DO NOT match any lines ending in #wasta
sed -i -e '/#wasta$/! s@.*\(deb .*ubuntu.com/ubuntu.* '$SERIES' \)@\1@' $APT_SOURCES
sed -i -e '/#wasta$/! s@.*\(deb .*ubuntu.com/ubuntu.* '$SERIES'-updates \)@\1@' $APT_SOURCES
sed -i -e '/#wasta$/! s@.*\(deb .*ubuntu.com/ubuntu.* '$SERIES'-security \)@\1@' $APT_SOURCES

# canonical.com lists include "partner" for things like skype, etc.
# DO NOT match any lines ending in #wasta
sed -i -e '/#wasta$/! s@.*\(deb .*canonical.com/ubuntu.* '$SERIES' \)@\1@' $APT_SOURCES

# legacy cleanup: PSO should NOT be in sources.list anymore (ubiquity will
#   remove when installing)
sed -i -e '\@http://packages.sil.org/ubuntu@d' $APT_SOURCES

# install repository Keys (done locally since wasta-offline could be active)
echo
echo "*** Adding Repository GPG Keys"
echo

# Manually add repo keys:
#   - apt-key no longer supported in scripts so need to use gpg directly.
#       - Still works 18.04 but warning it may break in the future: however
#         the direct gpg calls were problematic so keeping same for bionic.
#   - sending output to null to not scare users
apt-key add $DIR/keys/sil-2016.gpg > /dev/null 2>&1
apt-key add $DIR/keys/wasta-linux-ppa.gpg > /dev/null 2>&1

# add SIL repository
if ! [ -e $APT_SOURCES_D/packages-sil-org-$SERIES.list ];
then
    echo
    echo "*** Adding SIL Repository"
    echo

    echo "deb http://packages.sil.org/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/packages-sil-org-$SERIES.list
    echo "# deb-src http://packages.sil.org/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/packages-sil-org-$SERIES.list
else
    # found, but ensure PSO main ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://packages.sil.org\)@\1@' \
        $APT_SOURCES_D/packages-sil-org-$SERIES.list
fi

# add SIL Experimental repository
if ! [ -e $APT_SOURCES_D/packages-sil-org-$SERIES-experimental.list ];
then
    echo
    echo "*** Adding SIL Experimental Repository (inactive)"
    echo

    echo "# deb http://packages.sil.org/ubuntu $SERIES-experimental main" | \
        tee $APT_SOURCES_D/packages-sil-org-$SERIES-experimental.list
    echo "# deb-src http://packages.sil.org/ubuntu $SERIES-experimental main" | \
        tee -a $APT_SOURCES_D/packages-sil-org-$SERIES-experimental.list
fi

# add Wasta-Linux PPA
if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list ];
then
    echo
    echo "*** Adding Wasta-Linux PPA"
    echo

    echo "deb http://ppa.launchpad.net/wasta-linux/wasta/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list
    echo "# deb-src http://ppa.launchpad.net/wasta-linux/wasta/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list
else
    # found, but ensure Wasta-Linux PPA ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
        $APT_SOURCES_D/wasta-linux-ubuntu-wasta-$SERIES.list
fi

# add Wasta-Apps PPA
if ! [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list ];
then
    echo
    echo "*** Adding Wasta-Linux Apps PPA"
    echo

    echo "deb http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu $SERIES main" | \
        tee $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list
    echo "# deb-src http://ppa.launchpad.net/wasta-linux/wasta-apps/ubuntu $SERIES main" | \
        tee -a $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list
else
    # found, but ensure Wasta-Apps PPA ACTIVE (user could have accidentally disabled)
    # DO NOT match any lines ending in #wasta
    sed -i -e '/#wasta$/! s@.*\(deb http://ppa.launchpad.net\)@\1@' \
        $APT_SOURCES_D/wasta-linux-ubuntu-wasta-apps-$SERIES.list
fi

# IF Wasta-Testing PPA found, remove (do NOT want users having this, also
#   developers should only temporarily have it)
if [ -e $APT_SOURCES_D/wasta-linux-ubuntu-wasta-testing-$SERIES.list ];
then
    echo
    echo "*** REMOVING Wasta-Linux Testing PPA"
    echo
    rm -f $APT_SOURCES_D/wasta-linux-ubuntu-wasta-testing-$SERIES*
fi

# remove any partial updates: these are often broken if they exist
if [ -e /var/lib/apt/lists/partial/ ];
then
    rm -r /var/lib/apt/lists/partial/
fi

# ------------------------------------------------------------------------------
# preseed debconf with settings so user NOT prompted on package installs, etc.
# ------------------------------------------------------------------------------
# lightdm: set as display manager:
echo "lightdm shared/default-x-display-manager select lightdm" \
    | debconf-set-selections

# libdvd-pkg
# don't think needed: libdvd-pkg libdvd-pkg/post-invoke_hook-remove boolean false
echo "libdvd-pkg libdvd-pkg/build boolean true" \
    | debconf-set-selections
echo "libdvd-pkg libdvd-pkg/post-invoke_hook-install boolean true" \
    | debconf-set-selections

# ttf-mscorefonts-installer
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula boolean true" \
    | debconf-set-selections

# ------------------------------------------------------------------------------
# openssh server re-config
# ------------------------------------------------------------------------------
# machines created from ISO from Remastersys 3.0.4 stock will have some key files
#   missing needed for ssh server to work correctly

# 2017-11-29 rik: keeping for bionic (can't hurt) but maybe not needed anymore
# ***FOCAL?***
#
# don't print out errors (so will be blank if ssh not installed)
OPENSSH_INSTALLED=$(dpkg --status openssh-server 2>/dev/null \
    | grep Status: | grep installed || true;)
if [ "${OPENSSH_INSTALLED}" ];
then
    echo
    echo "*** Reconfiguring openssh-server"
    echo
    # This command will just re-create missing files: will not change existing
    #   settings
    dpkg-reconfigure openssh-server
fi

# ------------------------------------------------------------------------------
# qt5 app theme adjustment
# ------------------------------------------------------------------------------
# note: MAY need combo of: (previously I had done QT5_QPA_PLATFORMTHEME but
#   I don't think it is used / needed anymore???
#   QT5_QPA_PLATFORMTHEME=gtk2
#   QT_QPA_PLATFORMTHEME=gtk2
#   QT_STYLE_OVERRIDE=gtk2
QT_QPA_FOUND=$(grep QT_QPA_PLATFORMTHEME /etc/environment)
if [ "$QT_QPA_FOUND" == "" ];
then
    echo
    echo "*** Ensuring Qt app theme compatibilty"
    echo
    sed -i -e '$a QT_QPA_PLATFORMTHEME=gtk2' /etc/environment
fi

# ------------------------------------------------------------------------------
# disable apport error reporting
# ------------------------------------------------------------------------------
if [ -e /etc/default/apport ];
then
    echo
    echo "*** Disabling apport error reporting"
    echo
    sed -i -e 's@enabled=1@enabled=0@' /etc/default/apport
else
    cat << EOF > /etc/default/apport
enabled=0
EOF
fi

# ------------------------------------------------------------------------------
# disable release-upgrade prompts
# ------------------------------------------------------------------------------

# can't be put in /etc/update-manager/release-upgrades.d/ since not respected:
#   https://askubuntu.com/questions/611837/why-does-software-updates-affects-do-release-upgrade-command-in-terminal#612226

# also done in wasta-multidesktop to ensure user NEVER faces this prompt
if [ -e /etc/update-manager/release-upgrades ];
then
    echo
    echo "*** Disabling release-upgrade prompts"
    echo
    sed -i -e 's@Prompt=.*@Prompt=never@' /etc/update-manager/release-upgrades
else
    cat << EOF > /etc/update-manager/release-upgrades
Prompt=never
EOF
fi

# ------------------------------------------------------------------------------
# usb_modeswitch: enable SetStorageDelay
# ------------------------------------------------------------------------------
if [ -e /etc/usb_modeswitch.conf ];
then
    echo
    echo "*** usb_modeswitch: enabling SetStorageDelay"
    echo
    sed -i -e 's@#.*\(SetStorageDelay\)=.*@\1=4@' /etc/usb_modeswitch.conf
fi

# ------------------------------------------------------------------------------
# Dconf / Gsettings Default Value adjustments
# ------------------------------------------------------------------------------
# Values in /usr/share/glib-2.0/schemas/z_10_wasta-core.gschema.override
#   will override Ubuntu defaults.
# Below command compiles them to be the defaults
echo
echo "*** Updating dconf / gsettings default values"
echo

# MAIN System schemas: we have placed our override file in this directory
# Sending any "error" to null (if key not found don't want to worry user)
glib-compile-schemas /usr/share/glib-2.0/schemas/ # > /dev/null 2>&1 || true;

# Some Unity dconf values have no schema, need to manually set:
# /org/compiz/profiles/unity/plugins/unityshell/icon-size 32   NO SCHEMA
# /org/compiz/profiles/unity/plugins/expo/x-offset 48   NO SCHEMA

# ------------------------------------------------------------------------------
# Reduce "Swappiness"
# ------------------------------------------------------------------------------
# https://sites.google.com/site/easylinuxtipsproject/first
#   (default is 60, which means it goes to swap too quickly when low ram)
sed -i -e '$a vm.swappiness=10' \
    -i -e '\#vm.swappiness#d' \
    /etc/sysctl.conf

# ------------------------------------------------------------------------------
# Finished
# ------------------------------------------------------------------------------
echo
echo "*** Script Exit: wasta-core-postinst.sh"
echo

exit 0
