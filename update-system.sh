#!/bin/bash

LOG_FILE="/var/log/patching.log"
MAJOR_PACKAGES=(
        "python3"
        "python3.8"
        "systemd"
        "dpkg"
        "update-manager-core"
        "apache2"
        "nginx"
        "nginx-core"
        "nginx-common"
        "php8.3-cli"
        "php8.3-common"
        "php8.3-mysql"
        "php8.3-opcache"
        "php8.3-readline"
        "mariadb-server"
        "mariadb-server-core"
        "mysql-server"
        "elasticsearch"
        "galera"
        "salt-common"
        "salt-minion"
)

# Detect installed PHP packages and add them to the Major Pkg array
PHP_PACKAGES=(
        $(apt list --installed 2>/dev/null | grep -E "^php[0-9]+\." | awk -F/ '{print $1}')
)
MAJOR_PACKAGES+=(
        ${PHP_PACKAGES[@]}
)

log() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting system update process."

log "Updating package lists..."
sudo apt update || {
        log "Failed to update package lists.";
        exit 1;
}

log "Checking for pending updates..."

PENDING_UPDATES=$(apt list --upgradable 2>/dev/null | awk -F/ 'NR>1 {print $1}')

echo "$PENDING_UPDATES" | tee -a "$LOG_FILE"

log "Identifying major package updates..."

for pkg in "${MAJOR_PACKAGES[@]}"; do
        # Ensure package is installed before upgrading
        if dpkg -l | grep -qw "$pkg"; then
                if echo "$PENDING_UPDATES" | grep -qw "$pkg"; then
                        log "Major package found: $pkg"
                        log "Checking installed and available versions for $pkg..."
                        apt-cache policy "$pkg" | tee -a "$LOG_FILE"
                        log "Starting upgrade of $pkg..."
                        if sudo apt install --only-upgrade -y "$pkg"; then
                                log "Successfully upgraded $pkg."
                        else
                                log "Failed to upgrade $pkg."
                        fi
                fi
        else
                log "Skipping $pkg as it is not installed."
        fi
done

log "Upgrading remaining packages..."

REMAINING_UPDATES=$(echo "$PENDING_UPDATES" | grep -wv -F "$(printf "%s\n" "${MAJOR_PACKAGES[@]}")")

for pkg in $REMAINING_UPDATES; do
        log "Starting upgrade of $pkg..."
        if sudo apt install --only-upgrade -y "$pkg"; then
                log "Successfully upgraded $pkg."
        else
                log "Failed to upgrade $pkg."
        fi
done

# Check main services
log "Checking system logs for errors..."
dmesg -T 2>/dev/null | tee -a "$LOG_FILE"

if [ -f /var/run/reboot-required ]; then
        log "Reboot required. Make sure you reboot the server..."
        # Uncomment if you need a restart without safe-shutdown of svcs
        # sudo reboot -f
        sudo shutdown -r +0.1667 "Rebooting in 10 seconds..."
else
        log "No reboot required."
fi

log "Removing unused kernel and packages..."

sudo apt autoremove -y || log "Failed to remove unused packages."

log "Patching process completed."

exit 0
