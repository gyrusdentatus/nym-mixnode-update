#!/bin/bash

## Colours variables for the installation script
RED='\033[1;91m'    # WARNINGS
YELLOW='\033[1;93m' # HIGHLIGHTS
WHITE='\033[1;97m'  # LARGER FONT
LBLUE='\033[1;96m'  # HIGHLIGHTS / NUMBERS ...
LGREEN='\033[1;92m' # SUCCESS
NOCOLOR='\033[0m'   # DEFAULT FONT

# Find the systemd.service file and its name
#service_name=$(find /etc/systemd/system/ -name "nym-mixnode*" | grep -v multi-user | cut -d / -f 5)
service_name=$(basename $(find /etc/systemd/system/ -type f -name "nym-mixnode*" | grep -v multi-user) 2>/dev/null)

if [ "${service_name}" == "" ]; then
	echo "Unit file not found, exitting"
	exit 1
fi

if pgrep -fi nym-mixnode >/dev/null 2>&1; then
	echo "Node is running...proceeding"
else
	echo "Mixnode is not running, try to restart it with systemctl restart ${service_name} or run it please so this script could get all needed variables"
	exit 1
fi

## get mixnode full path so we could replace it precisely

mixnode_path="$(readlink -f /proc/$(pgrep -fi nym-mixnode)/exe)"
## get user running the program if we needed chown
mixnode_user=$(ps -A -o user | grep '[n]ym' | cut -d ' ' -f 1 | head -n 1)
## get binary name so we can change it later after download
binary_name="$(basename ${mixnode_path})"

## just testing if vars work properly
#echo $mixnode_path
#echo $mixnode_user
#echo $binary_name
#echo $service_name

function downloader() {

	# set vars for version checking and url to download the latest release of nym-mixnode
	current_version=$(${mixnode_path} --version | grep Nym | cut -c 13-)
	VERSION=$(curl -s https://github.com/nymtech/nym/releases/latest | grep -E -o "[0-9|\.]{6}(-\w+)?")
	URL="https://github.com/nymtech/nym/releases/download/v$VERSION/nym-mixnode_linux_x86_64"
	echo ${service_name}
	# Check if the version is up to date. If not, fetch the latest release.
	#set -x
	if [ ! -f "${mixnode_path}" ] || [ "${current_version}" != "$VERSION" ]; then
		if systemctl status "${service_name}" | grep -e "active (running)" >/dev/null 2>&1 && echo ${service_name}; then
			echo "stopping ${service_name} to update the node ..."
			systemctl kill --signal=SIGINT ${service_name}
		else
			echo " nym-mixnode.service is inactive or not existing. Downloading new binaries ...$(pwd)"
		fi
		echo "Fetching the latest version...$(pwd)"
		curl -L -o nym-mixnode_linux_x86_64 ${URL}
		chmod +x ./nym-mixnode_linux_x86_64
		rm -f ${mixnode_path} && cp ./nym-mixnode_linux_x86_64 ${mixnode_path} && rm ./nym-mixnode_linux_x86_64
		chown ${mixnode_user}:${mixnode_user} ${mixnode_path}
		curl -L -s "$URL" -o "nym-mixnode_linux_x86_64"

	else
		echo "You already have the latest version of Nym-mixnode $VERSION"
		exit 1
	fi
}
function upgrade_nym() {
	cd /home/${mixnode_user}/
	select d in .nym/mixnodes/*; do
		test -n "${d}" && break
		printf "%b\n\n\n" "${WHITE} >>> Invalid Selection"
	done
	directory=$(basename "${d}")
	printf "%b\n\n\n"
	printf "%b\n\n\n" "${WHITE} You selected ${YELLOW} ${directory}"
	sleep 2
	#set -x
	if [[ ${mixnode_user} != "root" ]]; then
		sudo -u ${mixnode_user} -H ./${binary_name} upgrade --id ${directory}
		sleep 2
	elif [[ ${mixnode_user} == "root" ]]; then
		$mixnode_path upgrade --id ${directory}
		sleep 2
	fi
}
  if [[ ("$1" = "--sign") ||  "$1" = "-g" ]]
  then
    printf "%b\n\n\n" "${WHITE} Please select a ${YELLOW} mixnode"
    printf "%b\n\n\n"
    select d in ${mixnode_path}.nym/mixnodes/* ; do test -n "$d" && break; printf "%b\n\n\n" "${WHITE} >>> Invalid Selection"; done
    directory=$(printf "%b\n\n\n" "${WHITE}$d" | rev | cut -d/ -f1 | rev)
    cd /home/nym || exit 2
    printf "\e[1;82mYou selected\e[0m\e[3;11m ${WHITE} $directory\e[0m\n"
    printf "%b\n\n\n"
    printf "%b\n\n\n" "${WHITE} Enter your Telegram handle beginning with @"
    printf "%b\n\n\n"
    read telegram
    printf "%b\n\n\n" "${WHITE} Your Telegram handle for the bot will be ${YELLOW} ${telegram} "
    printf "%b\n\n\n"
    printf "%b\n\n\n" "${WHITE} Enter your PUNK address"
    printf "%b\n\n\n" 
    read wallet
    printf "%b\n\n\n" "${WHITE} --------------------------------------------------------------------------------"
    # borrows a shell for nym user to initialize the node config.
    #set -x
    sudo -u nym -H /home/nym/nym-mixnode_linux_x86_64 sign --id $directory --text "${telegram} ${wallet}" 2>&1 | tee -a ${directory}_claim.txt && chown nym:nym ${directory}_claim.txt
    printf "%b\n\n\n"
  fi

downloader && echo "ok" && sleep 2 || exit 1
upgrade_nym && sleep 5 && systemctl start $service_name && printf "%b\n\n\n" "${WHITE} Check if the update was successful - ${YELLOW} systemctl status ${service_name}"
