#!/usr/bin/bash

set -ou pipefail

#Defining variables
user=$(whoami)
sudo_cmd=""
image="$1"
tar_file="${image}.tar.gz"

#Setting up the cleanup function that activates only when the user exits the workspace
cleanup() {
  $sudo_cmd umount -R workspace/ >/dev/null 2>&1
  $sudo_cmd chattr -R -i workspace/ >/dev/null 2>&1
  $sudo_cmd rm -rf workspace/ >/dev/null 2>&1
  echo "Workspace deleted!"
}


#checking if sudo is needed in front
if command -v sudo >/dev/null 2>&1 ;then #Checking if sudo even exists to be used
    if [[ $user != "root" ]];then
        sudo_cmd="sudo"
    fi
fi

#Docker is needed for the docker export and docker create so checking if it exists
if ! command -v docker >/dev/null 2>&1 ;then
    echo "You have to first install docker"
    exit 1
fi

#Again checking if tar exists as it is used for the docker image file
if ! command -v tar >/dev/null 2>&1 ;then
    echo "You have to first install tar"
    exit 1
fi

echo "This might take a few moments."
sleep 0.6

$sudo_cmd docker export "$($sudo_cmd docker create "$image")" -o "$image".tar.gz

mkdir -p workspace
mv "$tar_file" workspace
cd workspace || exit

$sudo_cmd tar --no-same-owner --no-same-permissions --owner=0 --group=0  -mxf "$tar_file"
rm -f "$tar_file"

#Configuring /dev/null in case it does not exist
mknod -n 666 workspace/dev/null c 1 3 >/dev/null 2>&1

cd ..
#Using unshare for namespace isolation with random bootime and monotonic
$sudo_cmd unshare --pid --uts --fork --net --mount-proc -T --boottime 8372 --monotonic 3819 --ipc --map-current-user bash -c "
  hostname workspace
  mount -t proc proc workspace/proc
  chroot workspace /bin/bash
"
#Using trap to trigger the cleanup function when user exits
trap "cleanup" EXIT

