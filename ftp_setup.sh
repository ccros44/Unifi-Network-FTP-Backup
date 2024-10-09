#!/bin/bash

# Help Information
helpFunction()
{
  echo ""
  echo "Usage Example: $0 -h 01 -m 10 -f /CloudKeys/Client/Folder/ -i ftp://192.168.0.1:21 -u admin -p admin"
  echo -e "\t-h - The hour that you want the backup to run"
  echo -e "\t-m - The minute you want the backup to run"
  echo -e "\t-f - Folder on the FTP server where you want to backup to"
  echo -e "\t-i - Address of the FTP server"
  echo -e "\t-u - Username of the FTP server"
  echo -e "\t-p - Password of the FTP server"
  exit 1 # Exit script after printing help
}

# Get Parameters
while getopts "h:m:f:i:u:p:" opt
do
  case "$opt" in
    h ) parameterH="$OPTARG" ;;
    m ) parameterM="$OPTARG" ;;
    f ) parameterF="$OPTARG" ;;
    i ) parameterI="$OPTARG" ;;
    u ) parameterU="$OPTARG" ;;
    p ) parameterP="$OPTARG" ;;
    ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
  esac
done

# Print Help in case parameters are empty
if [ -z "$parameterH" ] || [ -z "$parameterM" ] || [ -z "$parameterF" ] || [ -z "$parameterI" ] || [ -z "$parameterU" ] || [ -z "$parameterP" ]
then
  echo "Some or all of the parameters are empty";
  helpFunction
fi

# Check if running as root
echo ""
echo "Checking privileges."
if [ "$EUID" -ne 0 ]
  then echo "Please run as root or sudo /bin/bash."
  exit 1 #needs root for apt update and install as well as script creation chmod
fi
echo "Running as root."

# Check if autobackup is in the right location
echo ""
echo "Checking Unifi OS version and hardware."
AUTOBACKUP_LOCATION=$([ -d "/data/unifi/data/backup/autobackup" ] && echo "autobackup exists.")
if [ "" = "$AUTOBACKUP_LOCATION" ]; then
  echo "Unifi OS is out of date, or this script is runnning on unsupported hardware."
  exit 1 #cannot run unless autobackup is in the correct location
fi
echo "Running on correct Unifi OS version and hardware."

# Check if autobackup has files to backup
echo ""
echo "Checking autobackup folder contents."
files=$(shopt -s nullglob dotglob; echo /data/unifi/data/backup/autobackup/*)
if (( ${#files} ))
then
  echo "Unifi Network appears to be backing up files to autobackup."
else 
  echo ""
  echo "!!WARNING!!"
  echo "autobackup is empty."
  echo "!!WARNING!!"
  echo "Check the settings for Unifi network's backup schedule."
  echo ""
  echo "The script will now proceed with the lftp_autoupload setup."
fi

#apt update
echo ""
echo "Running an apt update."
sudo apt update

# Check for LFTP
echo ""
echo "Checking if LFTP is installed."
LFTP_CHECK=$(dpkg-query -W --showformat='${Status}\n' lftp | grep "install ok installed")
echo "LFTP: $LFTP_CHECK"
if [ "" = "$LFTP_CHECK" ]; then
  echo "LFTP is not installed. Installing now."
  sudo apt-get --yes install lftp
fi

# Check for nano
echo ""
echo "Checking if Nano is installed."
NANO_CHECK=$(dpkg-query -W --showformat='${Status}\n' nano | grep "install ok installed")
echo "Nano: $NANO_CHECK"
if [ "" = "$NANO_CHECK" ]; then
  echo "Nano is not installed. Installing now."
  sudo apt-get --yes install nano
fi

# Check if lftp_autoupload.sh exists
echo ""
echo "Checking for pre-existing lftp_autoupload.sh script."
if [ -e /data/unifi/data/backup/lftp_autoupload.sh ]
then
  echo "Upload script lftp_autoupload.sh appears to be in place."
else
  touch /data/unifi/data/backup/lftp_autoupload.sh
  echo '#!/bin/bash' > /data/unifi/data/backup/lftp_autoupload.sh
  echo 'HOST='$parameterI'' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'USER='$parameterU'' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'PASS='$parameterP'' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'TARGETFOLDER='$parameterF'' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'SOURCEFOLDER='/data/unifi/data/backup/autobackup/'' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo '' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'lftp -f "' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'set ssl:verify-certificate false' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'open $HOST' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'user $USER $PASS' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'lcd $SOURCEFOLDER' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'mirror --reverse --delete --verbose $SOURCEFOLDER $TARGETFOLDER' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo 'bye' >> /data/unifi/data/backup/lftp_autoupload.sh
  echo '"' >> /data/unifi/data/backup/lftp_autoupload.sh
  chmod +x /data/unifi/data/backup/lftp_autoupload.sh
  echo "Upload script lftp_autoupload.sh has been created."
fi

#Check for previous crontab LFTP entries
echo ""
echo "Checking if lftp_autoupload entry already exists in crontab."
CRONTAB_LFTP=$(crontab -l | grep "/data/unifi/data/backup/lftp_autoupload.sh")
if [ "" != "$CRONTAB_LFTP" ]; then
  echo "Cron job is already installed."
  echo ""
  exit 0
fi

#Install crontab schedule
(crontab -l ; echo "$parameterM $parameterH * * 0 /data/unifi/data/backup/lftp_autoupload.sh") | crontab -
echo "Cron job has been successfully installed"
echo ""
exit 0
