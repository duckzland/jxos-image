#!/bin/bash
# Script for performing final JXOS setup

# When invoked at boot, we need to wait until nvidia is detected to avoid 
# loading nvidia services when no nvidia card found in the system

PATH="/home/jxminer"
FILE_PATH="/home/jxminer/setup/files"
NVIDIA=`/usr/bin/lspci | /bin/grep -i "NVIDIA" | /usr/bin/wc -l`

echo "[ JXOS ] Starting dhclient"
/sbin/dhclient

# Already configured bailing out
if [ -f $PATH/.setup-completed ];
then
    echo "[ JXOS ] Already completed setup previously, remove $PATH/.setup-completed file to re-setup again."
    exit 0
fi


# Setting up NVIDIA
# Bugs in Ubuntu 18 can cause infinite udev loop of death if we install nvidia related services when the machine
# has no nvidia adapter on it
if [ $NVIDIA -eq 0 ];
then
    echo "[ JXOS ] No NVIDIA graphics adapter found"
else
    if [ ! -f /lib/systemd/system/nvidia-persistenced.service ];
    then
        echo "[ JXOS ] Setting up NVIDIA adapter"
        echo "[-] Enabling NVIDIA persistenced"
        /bin/cp $FILE_PATH/71-nvidia.rules /lib/udev/rules.d/71-nvidia.rules
        /bin/cp $FILE_PATH/nvidia-persistenced.service /lib/systemd/system/nvidia-persistenced.service
        /bin/systemctl daemon-reload
        /bin/systemctl enable nvidia-persistenced

        echo "[-] Generating Xorg settings for nvidia-settings"
	/usr/bin/nvidia-xconfig -a --allow-empty-initial-configuration --use-display-device="DFP-O:/etc/X11/edid.bin" --connected-monitor="DFP=O" --cool-bits=31

        echo "[-] Restarting udev"
        /bin/systemctl restart udev

    fi
fi

# Setting up AMD
echo "[ JXOS ] Setting up AMD adapter"
echo "export LLVM_BIN=/opt/amdgpu-pro/bin" || tee /etc/profile.d/amdgpu-pro.sh


# Trying to detect the machine temperature and fan sensors
echo "[ JXOS ] Setting up Sensors"
/usr/sbin/sensors-detect --auto &> /dev/null

# Mark that the setup completed
echo "[ JXOS ] Setup complete"
echo " " > $PATH/.setup-completed

exit 0
