#!/usr/bin/env bash

OLD_HOST=$(hostname)

ask() {
    local reply prompt
    prompt='y/n'
    echo -n "$1 [$prompt] >> "
    read -r reply </dev/tty
    if [[ -z $reply ]]; then
        return 1;
    elif [ "$reply" == "y" ] || [ "$reply" == "Y" ]; then
        return 0;
    else
        return 1;
    fi
}

# get the last part of the IP address:
ip_sfx=$(ip -o addr show dev "wlp4s0" | awk '$3 == "inet" {print $4}' | sed -r 's!/.*!!; s!.*\.!!')
# subtract 100 to get the device number:
WAFFLE_NO=$(($ip_sfx-100))

if ask "[INPUT] Preparing to configure for robot: dia-waffle$WAFFLE_NO. IS THIS CORRECT??"; then
    echo "[INFO] Updating hostname..."
    sudo hostnamectl set-hostname dia-waffle$WAFFLE_NO
    sudo sed -i 's/'$OLD_HOST'/dia-waffle'$WAFFLE_NO'/g' /etc/hosts
    if ask "[INPUT] Do you want to update the OpenCR board firmware?"; then
        export OPENCR_PORT=/dev/ttyACM0
        export OPENCR_MODEL=waffle
        cd $HOME/firmware/opencr_update/
        ./update.sh $OPENCR_PORT $OPENCR_MODEL.opencr
        cd ~
        echo "[INFO] OpenCR firmware *should* now be updated!"
        sleep 5
    else
        echo "[INFO] Skipped OpenCR updates."
    fi
    echo "[INFO] Checking for a RealSense Camera..."
    rs-fw-update -l
    if ask "[INPUT] is the RealSense Camera visible in the device list above?"; then
        if ask "[INPUT] Update the RealSense Camera Firmware (to 05.15.0.2)?"; then
            rs-fw-update -f ~/firmware/realsense/Signed_Image_UVC_5_15_0_2.bin
            sleep 5
            echo "[INFO] Checking the RealSense Camera Firmware (again)..."
            rs-fw-update -l
            echo "[INFO] Camera firmware version should now be displayed above as 05.15.0.2 (hopefully!)"
        else
            echo "[INFO] Skipped RealSense Firmware updates."
        fi
    else
        echo "[INFO] Skipped RealSense Firmware updates."
    fi
    sleep 5
    echo "[COMPLETE] Robot configuration is now complete."
    echo "IT IS NOW SAFE TO TURN OFF YOUR ROBOT!!!"
    if ask "[INPUT] Do you want to shutdown the robot now?"; then
        echo "[INFO] Powering off..."
        sudo poweroff
    else
        echo "[INFO] Don't forget to reboot/poweroff ASAP."
    fi
else
    echo "[INFO] CANCELLED."
fi
