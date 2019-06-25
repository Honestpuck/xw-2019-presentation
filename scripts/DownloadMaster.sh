#!/bin/bash
#
# DownloadMaster.sh

usr="YXBpX3JlYFAKEWRfb25seQo="
pass="cmVhZFAKEG9ubHkK"

Configuration_Profile_Download.sh $usr $pass
EncryptedStrings.sh* $usr $pass
Extension_Attribute_Download.sh $usr $pass
Group_Download.sh $usr $pass
Packages_Download.sh $usr $pass
Policy_Download.sh $usr $pass
Script_Download.sh $usr $pass

cd /Users/Shared/Backups
git add *
git commit -m "Done $(date +%d-%m-%Y)""
