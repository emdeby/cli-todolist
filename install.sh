#!/bin/bash

# CONSTANTS
DEPENDENCIES=("figlet" "dialog")
DISTRO=$(cat /etc/os-release | grep ^NAME | sed 's/NAME="//; s/"$//')
SAFETY_MODE=false

case $1 in
    -S|--safety-mode)
        SAFETY_MODE=true
    ;;

    *)
        echo "Invalid argument '$1'!"
        exit
    ;;
esac

# FUNCTIONS
check_dependency() {        # check if dependencies are installed, if not: install.
    local DEPENDENCY="$1"

    if [[ "$DISTRO" == "Arch Linux" ]]
    then
        local CHECK="pacman -Q"
        local INSTALL="pacman -S"
    elif [[ "$DISTRO" == "Debian" || "$DISTRO" == "Ubuntu" ]]
    then
        local CHECK="apt list --installed"
        local INSTALL="apt install"
    fi

    if ! $CHECK $DEPENDENCY > /dev/null 2>&1
    then
        echo "Dependency '$DEPENDENCY' missing."
        read -s -n 1  -p "Need to install dependency '$DEPENDENCY', press enter to continue..."
        echo
        if sudo $INSTALL $DEPENDENCY
        then
            sleep 1
            echo "Dependency '$DEPENDENCY' installed successfully!"
            sleep 2
            sleep 0.5
        fi
    fi
}

abort() {
    echo "Aborting..."
    sleep 1
    echo "Cleaning up..."
    sleep 2
    if [[ -d /usr/local/lib/cli-todolist/ ]]
    then
        echo "Executing 'sudo rm -r /usr/local/lib/cli-todolist/'..."
        sleep 2
        sudo rm -r /usr/local/lib/cli-todolist/
        sleep 1
        echo " > Done!"
    fi

    if [[ -f cli-todolist ]]
    then
        echo "Executing 'rm cli-todolist'..."
        sleep 2
        rm cli-todolist
        sleep 1
        echo " > Done!"
    fi

    if [[ -f /usr/local/bin/cli-todolist ]]
    then
        echo "Executing 'sudo rm /usr/local/bin/cli-todolist '..."
        sleep 2
        sudo rm /usr/local/bin/cli-todolist
        sleep 1
        echo " > Done!"
    fi
    exit
}

########################

### MAIN ###
if ! pwd | grep cli-todolist > /dev/null 2>&1
    then
        echo "Please execute install.sh from pulled git repo."
        echo "Aborting..."
        exit
fi

if [[ $SAFETY_MODE == "false" ]]
then
    echo "Creating directory '/usr/local/lib/cli-todolist'"
    sleep 2
    sudo mkdir /usr/local/lib/cli-todolist
    echo " > Done!"
    sleep 2

    echo "Copy/pasting 'todolist_main.sh' into'/usr/local/lib/cli-todolist/'"
    sleep 2
    sudo cp todolist_main.sh /usr/local/lib/cli-todolist/todolist_main.sh
    echo " > Done!"
    sleep 2

    echo "Copy/pasting 'todolist_functions.sh' into'/usr/local/lib/cli-todolist/'"
    sleep 2
    sudo cp todolist_functions.sh /usr/local/lib/cli-todolist/todolist_functions.sh
    echo " > Done!"
    sleep 2

    echo "Creating file 'cli-todolist' in '$(pwd)'"
    sleep 2
    sudo touch cli-todolist
    echo " > Done!"
    sleep 2

    echo "Chaning permissions of 'cli-todolist' to 757"
    sleep 2
    sudo chmod 757 cli-todolist
    echo " > Done!"
    sleep 2

    echo "Pasting needed bash code into 'cli-todolist'"
    sleep 2
    echo '#!/usr/bin/env bash' >> cli-todolist
    echo 'source /usr/local/lib/cli-todolist/todolist_functions.sh' >> cli-todolist
    echo 'source /usr/local/lib/cli-todolist/todolist_main.sh' >> cli-todolist
    echo " > Done!"
    sleep 2

    echo "Making 'cli-todolist' executable"
    sleep 2
    sudo chmod +x cli-todolist
    echo " > Done!"
    sleep 2

    echo "Moving 'cli-todolist' into '/usr/bin/bin/'"
    sleep 2
    sudo mv cli-todolist /usr/local/bin/cli-todolist
    echo " > Done!"
    sleep 2

    for DEPENDENCY in "${DEPENDENCIES[@]}"
    do
        check_dependency $DEPENDENCY
    done

    echo "ALL DONE!"
elif [[ $SAFETY_MODE == "true" ]]
then
    read -p "Create directory '/usr/local/lib/cli-todolist'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Creating directory '/usr/local/lib/cli-todolist'"
        sleep 2
        sudo mkdir /usr/local/lib/cli-todolist
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Copy/paste' todolist_main.sh' into '/usr/local/lib/cli-todolist/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Copy/pasting 'todolist_main.sh' into '/usr/local/lib/cli-todolist/'"
        sleep 2
        sudo cp todolist_main.sh /usr/local/lib/cli-todolist/todolist_main.sh
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Copy/paste' 'todolist_functions.sh' into '/usr/local/lib/cli-todolist/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Copy/pasting 'todolist_functions.sh' into '/usr/local/lib/cli-todolist/'"
        sleep 2
        sudo cp todolist_functions.sh /usr/local/lib/cli-todolist/todolist_functions.sh
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Create file 'cli-todolist' in '$(pwd)'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Creating file 'cli-todolist' in '$(pwd)'"
        sleep 2
        sudo touch cli-todolist
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Change permissions of 'cli-todolist' to 757? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Changing permissions of 'cli-todolist' to 757"
        sleep 2
        sudo chmod 757 cli-todolist
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Paste needed bash code into 'cli-todolist'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Pasting needed bash code into 'cli-todolist'"
        sleep 2
        echo '#!/usr/bin/env bash' >> cli-todolist
        echo 'source /usr/local/lib/cli-todolist/todolist_functions.sh' >> cli-todolist
        echo 'source /usr/local/lib/cli-todolist/todolist_main.sh' >> cli-todolist
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Make 'cli-todolist' executable? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Making 'cli-todolist' executable"
        sleep 2
        sudo chmod +x cli-todolist
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    read -p "Move 'cli-todolist' into '/usr/bin/bin/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Moving 'cli-todolist' into '/usr/bin/bin/'"
        sleep 2
        sudo mv cli-todolist /usr/local/bin/cli-todolist
        echo " > Done!"
        sleep 2
    else
        abort
    fi

    echo
    for DEPENDENCY in "${DEPENDENCIES[@]}"
    do
        check_dependency $DEPENDENCY
    done

    echo "ALL DONE!"
fi