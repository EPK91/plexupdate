# Script to automagically update Plex Media Server on Synology NAS
#
# Must be run as root.
#
# Forked from:
# @author @martinorob https://github.com/martinorob
# https://github.com/martinorob/plexupdate/

# variables
plexPrefFolder="/volume1/PlexMediaServer/AppData/Plex Media Server"
tmpFolder="/tmp/plex"
waitPeriod=30

# create temp folder
mkdir -p $tmpFolder/ > /dev/null 2>&1

# get available version based on architecture
token=$(cat "$plexPrefFolder"/Preferences.xml | grep -oP 'PlexOnlineToken="\K[^"]+')
url=$(echo "https://plex.tv/api/downloads/5.json?channel=plexpass&X-Plex-Token=$token")
jq=$(curl -s ${url})

# use sed to strip anything after the hythen
newversion=$(echo $jq | jq -r '.nas."Synology (DSM 7.2.2+)".version' | sed -E 's/(.*)-.*/\1/')
echo `date +"%Y-%m-%d %T"` - New Version: $newversion

curversion=$(synopkg version "PlexMediaServer" | sed -E 's/(.*)-.*/\1/')
echo `date +"%Y-%m-%d %T"` - Current Version: $curversion

# compare version numbers
if [ "$newversion" != "$curversion" ]

# new version available
then

    # build download url
    echo `date +"%Y-%m-%d %T"` - New Version Available - Building download url
    /usr/syno/bin/synonotify PKGHasUpgrade '{"[%HOSTNAME%]": $(hostname), "[%OSNAME%]": "Synology", "[%PKG_HAS_UPDATE%]": "Plex", "[%COMPANY_NAME%]": "Synology"}'
    CPU=$(uname -m)
    url=$(echo "${jq}" | jq -r '.nas."Synology (DSM 7.2.2+)".releases[] | select(.build=="linux-'"${CPU}"'") | .url')

    # download new version
    echo `date +"%Y-%m-%d %T"` - Downloading New Version
    /bin/wget $url -P $tmpFolder/

    # install version
    echo `date +"%Y-%m-%d %T"` - Installing New Version
    /usr/syno/bin/synopkg install $tmpFolder/*.spk

    # wait for a period
    echo `date +"%Y-%m-%d %T"` - Wait $waitPeriod seconds
    sleep $waitPeriod

    # clean up files
    echo `date +"%Y-%m-%d %T"` - Removing Temp Files
    rm -rf $tmpFolder/*

    # start plex
    echo `date +"%Y-%m-%d %T"` - Starting Plex Media Server
    /usr/syno/bin/synopkg start "Plex Media Server"

# no new version
else
    echo `date +"%Y-%m-%d %T"` - No New Version
fi

exit
