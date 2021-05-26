# nym-mixnode-update

a simple shell script to update Nym mixnode to the latest version. (Draft version !!! It will not delete any of your keys or destroy your server, but I do not guarantee anything, right now at this stage - use at your own risk.)

## Usage and features:
### **WARNING:** People running Nym as root might get error, because the elif on line 75 might not find your mixnode id directory. I think it is fixed now but in case it happens - `/root/nym/target/release/nym-mixnode upgrade --id <YOUR-ID>` 
- your previous node version has to be running and with systemd else this script will not be able to get the vars needed for the update

- your node has to be running with systemd (I haven't figured a workaround)

- Tested on Debian 10 as a Nym user but script should work for root or any other user (you will need to run it with sudo right now to borrow nym user shell or other user shell, depends on how you're running this.

- You will be promted to select an id(directory) at the end of the script for the upgrade command, so make sure you pick the right one.

## Installation:
git clone https://github.com/gyrusdentatus/nym-mixnode-update 
cd nym-mixnode-update
chmod +x mixnode_update.sh
./mixnode_update.sh
TODO: Make this thing much simpler just by parsing the systemd.service file, I had a hard time writing this funny and simple shell script because of some silly mistakes I'd missed. It was fun nevertheless !
