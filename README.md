# Unifi Network – FTP Backup

**This project is a bash script that aims to automate the backup of Unifi Network’s backup files**

Unifi's automatic Cloud Backup solution has a few issues. The main one being that you can't restore your backup of a Unifi Console to Unifi hardware that’s a different model from the one where the backup was taken.

**AKA if you took the Unifi Console backup from a Unifi Dream Router and then try and restore it to a Unifi Cloud Gateway, it will only show you errors and fail to restore**

This presents a major issue if the model of Unifi hardware you were running isn’t available anymore, thus leaving you unable to restore your backup as you weren’t able to track down the same hardware that you originally had.

For example, the following hardware is technically still supported by Unifi, but can't be purchased anywhere due to Unifi ceasing production in favour of their new models:
 - Unifi CloudKey Gen 2
 - Unifi CloudKey Gen 2 Plus
 - Unifi Dream Machine
 - Unifi Dream Router

There is a solution. Most people don’t need a full backup of their Unifi Console. They're mainly interested in restoring a backup of just Unifi Network, the application that runs on top of Unifi Console for managing their network enviroment. With this in mind, I have put together this script. This script will automatically set up Unifi hardware running Unifi Network to send the Unifi Network backup files to an FTP server every  at a time of your choosing.

## Requirements

The script should work on all currently supported Unifi devices that run Unifi Network, but I have personally tested the script working on the following:
 - Unifi CloudKey Gen 2
 - Unifi CloudKey Gen 2 Plus
 - Unifi Dream Machine
 - Unifi Dream Router
 - Unifi Dream Machine Pro
 - Unifi Cloud Gateway
 - Unifi Express
 
 ## Usage 

Download the script, then execute it qith the parameters set to your use case.

```bash
curl -O https://raw.githubusercontent.com/ccros44/Unifi-Network-FTP-Backup/refs/heads/main/ftp_setup.sh
chmod +x ftp_setup.sh
./ftp_setup.sh -h 01 -m 10 -f '/FTP/Folder/For/Backups' -i 'ftp://192.168.0.1:21' -u 'admin' -p 'admin' -r 1
```

Edit the parameters of the last command as follows:
 - h - The hour that you want the backup to run.
 - m - The minute you want the backup to run.
 - f - Folder on the FTP server where you want to backup to. Put in '' to escape special characters.
 - i - IP address of the FTP server. Put in '' to escape special characters.
 - u - Username of the FTP server. Put in '' to escape special characters.
 - p - Password of the FTP server. Put in '' to escape special characters.
 - r - (OPTIONAL) Set -r to 1 to enable replacment of any lftp_autoupload.sh perviously created.

## Credits & Licence

This project is under the [GPL-3.0 license](https://raw.githubusercontent.com/ccros44/Unifi-Network-FTP-Backup/refs/heads/main/LICENSE)
