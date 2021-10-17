#!/bin/bash
# this installer script is heavily inspired by 
# https://github.com/protoloft/klipper_z_calibration/blob/master/install.sh


MOONRAKER_PATH="${HOME}/moonraker"
SYSTEMDDIR="/etc/systemd/system"
KLIPPER_CONFIG_PATH="${HOME}/klipper_config"


check_klipper()
{
    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "klipper.service")" ]; then
        echo "Klipper service found!"
    else
        echo "Klipper service not found, please install Klipper first"
        exit -1
    fi

}

check_moonraker()
{
    if [ "$(sudo systemctl list-units --full -all -t service --no-legend | grep -F "moonraker.service")" ]; then
        echo "Moonraker service found!"
    else
        echo "Moonraker service not found, please install Moonraker first"
        exit -1
    fi

}

link_extension()
{
    echo "Linking extension to moonraker..."
    ln -sf "${SRCDIR}/timelapse.py" "${MOONRAKER_PATH}/moonraker/components/timelapse.py"
	echo "Linking macro file"	
    ln -sf "${SRCDIR}/klipper_macro/timelapse.cfg" "${KLIPPER_CONFIG_PATH}/timelapse.cfg"
}

install_script()
{
# Create systemd service file
    SERVICE_FILE="${SYSTEMDDIR}/timelapse.service"
    #[ -f $SERVICE_FILE ] && return
    if [ -f $SERVICE_FILE ]; then
        sudo rm "$SERVICE_FILE"
    fi

    echo "Installing system start script..."
    sudo /bin/sh -c "cat > ${SERVICE_FILE}" << EOF
[Unit]
Description=Dummy Service for timelapse plugin
After=moonraker.service
[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'exec -a z_calibration sleep 1'
ExecStopPost=/usr/sbin/service klipper restart
TimeoutStopSec=1s
[Install]
WantedBy=multi-user.target
EOF
# Use systemctl to enable the systemd service script
    sudo systemctl daemon-reload
    sudo systemctl enable z_calibration.service
}

# Step 4: restarting Klipper
restart_klipper()
{
    echo "Restarting Klipper..."
    sudo systemctl restart klipper
}

# Helper functions
verify_ready()
{
    if [ "$EUID" -eq 0 ]; then
        echo "This script must not run as root"
        exit -1
    fi
}

# Force script to exit if an error occurs
set -e

# Find SRCDIR from the pathname of this script
SRCDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )"/ && pwd )"

# Parse command line arguments
while getopts "k:" arg; do
    case $arg in
        k) KLIPPER_PATH=$OPTARG;;
    esac
done

# Run steps
verify_ready
link_extension
install_script
restart_klipper
