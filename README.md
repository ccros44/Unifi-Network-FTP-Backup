# Unifi Network – FTP Backup

**This project is a bash script that automates creating Unifi Network backups and sending them to an FTP server.**

Unifi's automatic Cloud Backup solution has a few issues. The main one being that you can't restore your backup of a Unifi Console to Unifi hardware that’s a different model from the one where the backup was taken.

**AKA if you took the Unifi Console backup from a Unifi Dream Router and then try and restore it to a Unifi Cloud Gateway, it will only show you errors and fail to restore**

This presents a major issue if the model of Unifi hardware you were running isn’t available anymore, thus leaving you unable to restore your backup as you weren’t able to track down the same hardware that you originally had.

For example, the following hardware is technically still supported by Unifi, but can't be purchased anywhere due to Unifi ceasing production in favour of their new models:
 - Unifi CloudKey Gen 2
 - Unifi CloudKey Gen 2 Plus
 - Unifi Dream Machine
 - Unifi Dream Router

There is a solution. Most people don’t need a full backup of their Unifi Console. They're mainly interested in restoring a backup of just Unifi Network, the application that runs on top of Unifi Console for managing their network environment. With this in mind, I have put together this script. This script will automatically set up Unifi hardware running Unifi Network to create a Unifi Network backup and send it to an FTP server every week at a time of your choosing.

## How it works

Earlier versions of this script relied on Unifi Network's scheduled **auto-backup** files already being present on local storage (`/data/unifi/data/backup/autobackup`). Newer Unifi Network releases no longer reliably keep those files locally, so the script now **creates a fresh backup on demand via the Unifi Network local API** instead.

On a schedule, the generated upload script:
1. Authenticates to the local Network API with an **API key** (`X-API-KEY`) and triggers a new backup (`/proxy/network/api/s/<site>/cmd/backup`).
2. Downloads the resulting `.unf` file into a staging folder (`/data/unifi/data/backup/ftp_staging`), keeping the most recent 30 backups.
3. Mirrors the staging folder to your FTP server with `lftp`.

It also installs an `on_boot.d` handler so the schedule is automatically restored after a reboot, and it (re)installs `curl`/`lftp` at run time of the lftp_upload.sh script if a firmware update has removed them.

## Requirements

The script should work on all currently supported Unifi devices that run Unifi Network. It has been tested on:
 - Unifi CloudKey Gen 2
 - Unifi CloudKey Gen 2 Plus
 - Unifi Dream Machine
 - Unifi Dream Router
 - Unifi Dream Machine Pro
 - Unifi Cloud Gateway
 - Unifi Express

You will also need:
 - **A Unifi Network local API key** (see below).
 - **An FTP server** to receive the backups.
 - **Internet access on the console for the first run** — to install the [unifi-common](https://github.com/unifi-utilities/unifi-common) boot runner and, if missing, `curl`/`lftp`.

### Creating an API key

In the Unifi Network application go to **Settings → Control Plane → Integrations → Create API Key** (the exact path can vary slightly by version; on some builds it is under **Admins & Users → your admin → API Keys**). The key inherits the role of the admin who created it, so create it under an admin with full management rights.

## Usage

Download the script, then execute it as root with the parameters set to your use case.

```bash
curl -O https://raw.githubusercontent.com/ccros44/Unifi-Network-FTP-Backup/refs/heads/main/ftp_setup.sh
chmod +x ftp_setup.sh
sudo ./ftp_setup.sh -h 01 -m 10 -f '/FTP/Folder/For/Backups' -i 'ftp://192.168.0.1:21' -u 'admin' -p 'admin' -k 'your-api-key' -s 'default' -r 1
```

Edit the parameters of the last command as follows:
 - h - The hour that you want the backup to run.
 - m - The minute you want the backup to run.
 - f - Folder on the FTP server where you want to backup to. Put in '' to escape special characters.
 - i - IP address of the FTP server. Put in '' to escape special characters.
 - u - Username of the FTP server. Put in '' to escape special characters.
 - p - Password of the FTP server. Put in '' to escape special characters.
 - k - Unifi Network local API key. Put in '' to escape special characters.
 - s - (OPTIONAL) Unifi site name. Defaults to 'default'.
 - r - (OPTIONAL) Set -r to 1 to replace any lftp_autoupload.sh previously created.

The backup runs once a week (on Sunday) at the hour and minute you specify.

## Persistence & firmware updates

The script installs the community [unifi-common](https://github.com/unifi-utilities/unifi-common) boot runner (`udm-boot.service`) so the scheduled job is restored on every boot. The script and the schedule live under `/data`, which survives firmware updates, and `curl`/`lftp` are reinstalled automatically when missing.

One manual step remains: a firmware update wipes the boot runner service itself (it lives in `/etc`), so **after a major firmware update, re-run this script (or the `unifi-common` installer) once** to reinstate the runner. Everything downstream then self-heals.

## Credits & Licence

This project is under the [GPL-3.0 license](https://raw.githubusercontent.com/ccros44/Unifi-Network-FTP-Backup/refs/heads/main/LICENSE)
