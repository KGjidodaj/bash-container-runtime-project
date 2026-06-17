#!/usr/bin/bash

set -ou pipefail

user=$(whoami)
sudo_cmd=""
image="$1"
command="$2"
tar_file="${image}.tar.gz"

if command -v sudo >/dev/null 2>&1 ;then
    if [[ $user != "root" ]];then
        sudo_cmd="sudo"
    fi
fi

if ! command -v docker >/dev/null 2>&1 ;then
    echo "You have to first install docker"
    exit 1
fi

if ! command -v tar >/dev/null 2>&1 ;then
    echo "You have to first install tar"
    exit 1
fi

if [[ $command == "run" ]];then

    echo "This might take a few moments."
    sleep 0.6

    $sudo_cmd docker export $($sudo_cmd docker create $image) -o "$image".tar.gz

    mkdir -p workspace
    mv "$tar_file" workspace
    cd workspace

    $sudo_cmd tar --no-same-owner --no-same-permissions --owner=0 --group=0  -mxf "$tar_file"
    rm -f "$tar_file"

    cd ..
    $sudo_cmd chroot workspace /bin/bash

fi

if [[ $command == "delete" ]];then
    if [[ -d workspace ]];then
        $sudo_cmd umount -R workspace/ >/dev/null 2>&1
        $sudo_cmd chattr -R -i workspace/ >/dev/null 2>&1
        $sudo_cmd rm -rf workspace/ >/dev/null 2>&1
        echo "Workspace deleted!"
    else
        echo "Workspace directory does not exist"
    fi
fi
