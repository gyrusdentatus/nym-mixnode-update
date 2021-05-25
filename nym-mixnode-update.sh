#!/bin/bash





## Find the systemd.service file and its name 
service_name=$(find /etc/systemd/system/ -name "nym-mixnode*" | grep -v multi-user)

function get_vars () {

# Find the systemd.service file and its name 
service_name=$(find /etc/systemd/system/ -name "nym-mixnode*" | grep -v multi-user)

## get mixnode full path so we could replace it precisely

mixnode_path=$(ps -A -o pid,cmd |  grep '[n]ym' |  awk '{print $2}')
## get user running the program if we needed chown
mixnode_user=$(ps -A -o pid,cmd,user |  grep '[n]ym' | awk '{print $3}')
## get binary name so we can change it later after download
binary_name=$(pgrep -fi nym -a | awk -F "/" '{print $4}' | awk '{print $1}')


}

## check if the process is running
if pgrep -fi nym -a > /dev/null 2>&1
then echo "Node is running...proceeding"
else echo "Mixnode is not running, try to restart it with systemctl restart ${service_name} or run it please so this script could get all needed variables"
fi

function downloader () {
#set -x

# set vars for version checking and url to download the latest release of nym-mixnode
current_version=$(./nym-mixnode_linux_x86_64 --version | grep Nym | cut -c 13- )
VERSION=$(curl https://github.com/nymtech/nym/releases/latest --cacert /etc/ssl/certs/ca-certificates.crt 2>/dev/null | egrep -o "[0-9|\.]{6}(-\w+)?")
URL="https://github.com/nymtech/nym/releases/download/v$VERSION/nym-mixnode_linux_x86_64"

# Check if the version is up to date. If not, fetch the latest release.
if [ ! -f "$mixnode_path" ] || [ "$(./nym-mixnode_linux_x86_64 --version | grep Nym | cut -c 13- )" != "$VERSION" ]
   then
       if systemctl list-units --state=running | grep $service_name
          then echo "stopping $service.name to update the node ..." && systemctl kill --signal=SIGINT $service_name
                curl -L -s "$URL" -o "nym-mixnode_linux_x86_64" --cacert /etc/ssl/certs/ca-certificates.crt && echo "Fetching the latest version" && pwd
          else echo " nym-mixnode.service is inactive or not existing. Downloading new binaries ..." && pwd
    		curl -L -s "$URL" -o "nym-mixnode_linux_x86_64" --cacert /etc/ssl/certs/ca-certificates.crt && echo "Fetching the latest version" && pwd
	   # Make it executable
   chmod +x ./nym-mixnode_linux_x86_64 && cp ./nym-mixnode_linux_x86_64 /$mixnode_path && chown $mixnode_user:$mixnode_user ./$binary_name
   fi
else
   echo "You have the latest version of Nym-mixnode $VERSION"
   exit 1

fi

