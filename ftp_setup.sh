#!/bin/bash

# Help Information
helpFunction()
{
  echo ""
  echo "Usage Example: $0 -h 01 -m 10 -f '/CloudKeys/Client/Folder/' -i 'ftp://192.168.0.1:21' -u 'admin' -p 'admin' -r 1"
  echo -e "\t-h - The hour that you want the backup to run."
  echo -e "\t-m - The minute you want the backup to run."
  echo -e "\t-f - Folder on the FTP server where you want to backup to. Put in '' to escape special characters."
  echo -e "\t-i - IP address of the FTP server. Put in '' to escape special characters."
  echo -e "\t-u - Username of the FTP server. Put in '' to escape special characters."
  echo -e "\t-p - Password of the FTP server. Put in '' to escape special characters."
  echo -e "\t-r - (OPTIONAL) Set -r to 1 to enable replacment of any lftp_autoupload.sh perviously created."
  exit 1 # Exit script after printing help
}

# Get Parameters
while getopts "h:m:f:i:u:p:r:" opt
do
  case "$opt" in
    h ) parameterH="$OPTARG" ;;
    m ) parameterM="$OPTARG" ;;
    f ) parameterF="$OPTARG" ;;
    i ) parameterI="$OPTARG" ;;
    u ) parameterU="$OPTARG" ;;
    p ) parameterP="$OPTARG" ;;
    r ) parameterR="$OPTARG" ;;
    ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
  esac
done

# Print Help in case parameters are empty
if [ -z "$parameterH" ]; then
  echo "Missing -h parameter. Enter the hour you want the backup to run."
  helpFunction
elif [ -z "$parameterM" ]; then
  echo "Missing -m parameter. Enter the minute you want the backup to run."
  helpFunction
elif [ -z "$parameterF" ]; then
  echo "Missing -f parameter. Enter the folder on the FTP server you want to backup to."
  helpFunction
elif [ -z "$parameterI" ]; then
  echo "Missing -i parameter. Enter the address of the FTP server."
  helpFunction
elif [ -z "$parameterU" ]; then
  echo "Missing -u parameter. Enter the username of the FTP server."
  helpFunction
elif [ -z "$parameterP" ]; then
  echo "Missing -p parameter. Enter the password of the FTP server."
  helpFunction
elif [ -n "$parameterR" ]; then
  if [ "1" = "$parameterR" ]; then
    echo ""
    echo "-r set to 1. Will replace lftp_autoupload.sh if found"
  else
    echo "-r parameter not set correctly. Set to 1 to replace, or leave -r out."
    helpFunction
  fi
elif [ -z "$parameterR" ]; then
  echo ""
  echo "Missing -r parameter. Will not be replacing lftp_autoupload.sh if found."
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
echo "Running an Apt update."
sudo apt update
aptupdate_status=$?
if [ $aptupdate_status -eq 0 ]; then
  echo "Apt update was successful."
else
  echo "Apt update failed. Please check your Unifi OS configuration."
  exit 1 #issues with apt will prevent installation of dependencies
fi

# Check for LFTP
echo ""
echo "Checking if LFTP is installed."
LFTP_CHECK=$(dpkg-query -W --showformat='${Status}\n' lftp | grep "install ok installed")
echo "LFTP: $LFTP_CHECK"
if [ "" = "$LFTP_CHECK" ]; then
  echo "LFTP is not installed. Installing now."
  sudo apt-get --yes install lftp
  lftpinstall_status=$?
  if [ $lftpinstall_status -eq 0 ]; then
    echo "LFTP install was successful."
  else
    echo "LFTP install failed. Review apt logs and rectify error."
    exit 1 #LFTP is required to run the autoupload script.
  fi
fi

# Check for nano
echo ""
echo "Checking if Nano is installed."
NANO_CHECK=$(dpkg-query -W --showformat='${Status}\n' nano | grep "install ok installed")
echo "Nano: $NANO_CHECK"
if [ "" = "$NANO_CHECK" ]; then
  echo "Nano is not installed. Installing now."
  sudo apt-get --yes install nano
  nanoinstall_status=$?
  if [ $nanoinstall_status -eq 0 ]; then
    echo "NANO install was successful."
  else
    echo "NANO install failed. Review apt logs and rectify error."
    exit 1 #NANO is required to run the autoupload script.
  fi
fi

# Check if lftp_autoupload.sh exists
echo ""
echo "Checking for pre-existing lftp_autoupload.sh script."
if [ -e /data/unifi/data/backup/lftp_autoupload.sh ]; then
  if [ "1" = "$parameterR" ]; then
    echo "Upload script lftp_autoupload.sh found. -r is set to 1. Replacing now."
    rm -rf /data/unifi/data/backup/lftp_autoupload.sh
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
    echo "Upload script lftp_autoupload.sh has been replaced."
  else
    echo "Upload script lftp_autoupload.sh found. -r is not set to 1. Won't be replacing."
  fi 
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
croninstall_status=$?
if [ $croninstall_status -eq 0 ]; then
  echo "Cron job has been successfully installed."
  exit 0
else
  echo "Cron job could not be installed. The script has not been automated. Check cron logs and rectify error."
  exit 1 #Cron job needs to be installed to run automatically
fi
