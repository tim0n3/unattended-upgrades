# System Update Script

This script automates system updates by prioritizing critical packages such as `python3`, `systemd`, `dpkg`, `apache2`, `nginx`, `mariadb`, `mysql-server`, `elasticsearch`, `galera`, and all installed PHP versions. It logs all actions taken and ensures only installed packages are updated.

## Features
- Updates package lists before performing upgrades
- Prioritizes major system packages and all installed PHP versions
- Skips uninstalled packages to avoid unnecessary errors
- Logs update details to `/var/log/patching.log`
- Cleans up unused packages after updates
- Reboots the system if required

## Installation
To install and use this script on a server manually or through automation (cron/systemd), follow these steps:

### 1. Download and Install the Script
```sh
sudo curl -o /usr/local/bin/system-update.sh https://raw.githubusercontent.com/tim0n3/unattended-upgrades/refs/heads/main/system-update.sh
sudo chmod +x /usr/local/bin/system-update.sh
```

### 2. Run the Script Manually
```sh
sudo /usr/local/bin/system-update.sh
```

### 3. Automate with Cron
To schedule automatic updates, add the script to cron:
```sh
sudo crontab -e
```
Add the following line to run updates daily at 2 AM:
```sh
0 2 * * * /usr/local/bin/system-update.sh
```

### 4. Automate with Systemd Timer
Create a systemd service:
```sh
sudo nano /etc/systemd/system/system-update.service
```
Paste the following:
```
[Unit]
Description=Automated System Update

[Service]
ExecStart=/usr/local/bin/system-update.sh
```

Then create a systemd timer:
```sh
sudo nano /etc/systemd/system/system-update.timer
```
Paste the following:
```
[Unit]
Description=Run System Update Daily

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true

[Install]
WantedBy=timers.target
```
Enable and start the timer:
```sh
sudo systemctl enable system-update.timer
sudo systemctl start system-update.timer
```

## Logs & Monitoring
The script logs all updates to `/var/log/patching.log`. You can monitor updates with:
```sh
tail -f /var/log/patching.log
```

## License
This script is open-source and available under the MIT License.
