#!/bin/bash


## Colours variables for the installation script
RED='\033[1;91m' # WARNINGS
YELLOW='\033[1;93m' # HIGHLIGHTS
WHITE='\033[1;97m' # LARGER FONT
LBLUE='\033[1;96m' # HIGHLIGHTS / NUMBERS ...
LGREEN='\033[1;92m' # SUCCESS
NOCOLOR='\033[0m' # DEFAULT FONT

set -x

# Find the systemd.service file and its name
#service_name=$(find /etc/systemd/system/ -name "nym-mixnode*" | grep -v multi-user | cut -d / -f 5)
if pgrep -fi nym-mixnode > /dev/null 2>&1
  then echo "Node is running...proceeding"
  else echo "Mixnode is not running, try to restart it with systemctl restart ${service_name} or run it please so this script could get all needed variables"
    exit 1
fi
# Find the systemd.service file and its name
service_name=$(find /etc/systemd/system/ -name "nym-mixnode*" | grep -v multi-user | cut -d / -f 5)
## get mixnode full path so we could replace it precisely

mixnode_path=$(ps -A -o cmd |  grep '[n]ym' | cut -d ' ' -f 1 | head -n 1 )
## get user running the program if we needed chown
mixnode_user=$(ps -A -o user | grep '[n]ym' | cut -d ' ' -f 1 | head -n 1)
## get binary name so we can change it later after download
binary_name=$(ps -A -o cmd | grep '[n]ym' | cut -d ' ' -f 1 | head -n 1 | cut -d / -f 4)



echo $mixnode_path
echo $mixnode_user
echo $binary_name
echo $service_name
## check if the process is running
#if pgrep nym-mixnode > /dev/null 
#then echo "Node is running...proceeding"
#else echo "Mixnode is not running, try to restart it with systemctl restart ${service_name} or run it please so this script could get all needed variables"
#  exit 1
#fi

function downloader () {
#set -x

# set vars for version checking and url to download the latest release of nym-mixnode
current_version=$(./nym-mixnode_linux_x86_64 --version | grep Nym | cut -c 13- )
VERSION=$(curl https://github.com/nymtech/nym/releases/latest --cacert /etc/ssl/certs/ca-certificates.crt 2>/dev/null | egrep -o "[0-9|\.]{6}(-\w+)?")
URL="https://github.com/nymtech/nym/releases/download/v$VERSION/nym-mixnode_linux_x86_64"
echo ${service_name}
# Check if the version is up to date. If not, fetch the latest release.
set -x
if [ ! -f "$mixnode_path" ] || [ "$("${mixnode_path}" --version | grep Nym | cut -c 13- )" != "$VERSION" ]
   then
       if systemctl status "$service_name" | grep -e "active (running)" > /dev/null 2>&1 && echo $service_name
          then echo "stopping $service_name to update the node ..." && systemctl kill --signal=SIGINT $service_name
                curl -L -s "$URL" -o "nym-mixnode_linux_x86_64" --cacert /etc/ssl/certs/ca-certificates.crt && echo "Fetching the latest version" && pwd
          else echo " nym-mixnode.service is inactive or not existing. Downloading new binaries ..." && pwd
                curl -L -s "$URL" -o "nym-mixnode_linux_x86_64" --cacert /etc/ssl/certs/ca-certificates.crt && echo "Fetching the latest version" && pwd
           # Make it executable
   chmod +x ./nym-mixnode_linux_x86_64 && cp ./nym-mixnode_linux_x86_64 $mixnode_path && chown $mixnode_user:$mixnode_user ${mixnode_path}
   fi
else
   echo "You have the latest version of Nym-mixnode $VERSION"
   exit 1

fi
}
function upgrade_nym () {
set -x
if [[ $mixnode_user != "root" ]]
then cd /home/${mixnode_user}/
select d in .nym/mixnodes/* ; do test -n "$d" && break; printf "%b\n\n\n" "${WHITE} >>> Invalid Selection"; done
directory=$(echo "$d" | rev | cut -d/ -f1 | rev)
printf "%b\n\n\n"
printf "%b\n\n\n" "${WHITE} You selected ${YELLOW} $directory"
sleep 2
sudo -u $mixnode_user -H ./$binary_name upgrade --id $directory
sleep 2
elif [[ $USER = "root" ]]
then cd /root/
        select d in .nym/mixnodes/*; do test -n "$d" && break; printf "%b\n\n\n" "${WHITE} >>> Invalid Selection"; done
        directory=$(echo "$d" | rev | cut -d/ -f1 | rev)
	printf "%b\n\n\n"
	printf "%b\n\n\n" "${WHITE} You selected ${YELLOW} $directory"
	sleep 2 
	$mixnode_path upgrade --id $directory
	sleep 2 
fi
}

downloader && echo "ok" && sleep 2 || exit 1
upgrade_nym && sleep 5 && systemctl start $service_name && printf "%b\n\n\n" "${WHITE} Check if the update was successful - ${YELLOW} systemctl status ${service_name}"





