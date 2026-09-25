#!/bin/bash

if ! pwd | grep tui-todolist > /dev/null 2>&1
    then
        echo "Please execute install.sh from pulled git repo."
        echo "Aborting..."
        exit
fi

# CONSTANTS
DEPENDENCIES=("figlet" "dialog")
DISTRO=$(cat /etc/os-release | grep ^NAME | sed 's/NAME="//; s/"$//')
SAFETY_MODE=false

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

clean_up() {
    echo "Cleaning up..."
    sleep 1
    if [[ -d /usr/local/lib/tui-todolist/ ]]
    then
        echo "Executing 'sudo rm -r /usr/local/lib/tui-todolist/'..."
        sleep 1
        sudo rm -r /usr/local/lib/tui-todolist/
        sleep 1
        echo " > Done!"
    fi

    if [[ -f tui-todolist ]]
    then
        echo "Executing 'rm tui-todolist'..."
        sleep 1
        rm tui-todolist
        sleep 1
        echo " > Done!"
    fi

    if [[ -d ~/.config/tui-todolist/ ]]
    then
        echo "Executing 'sudo rm -r ~/.config/tui-todolist/'.."
        sleep 1
        sudo rm -r ~/.config/tui-todolist/
        sleep 1
        echo " > Done!"
    fi

    if [[ -d ~/.local/share/tui-todolist/ ]]
    then
        echo "Executing 'sudo rm -r ~/.local/share/tui-todolist/'.."
        sleep 1
        sudo rm -r ~/.local/share/tui-todolist/
        sleep 1
        echo " > Done!"
    fi
    
    if [[ -f /usr/local/bin/tui-todolist ]]
    then
        echo "Executing 'sudo rm /usr/local/bin/tui-todolist'..."
        sleep 1
        sudo rm /usr/local/bin/tui-todolist
        sleep 1
        echo " > Done!"
    fi
    exit
}

## ARGS ##
if [[ -n $1 ]]
then
    case $1 in
        -S|--safety-mode)
            SAFETY_MODE=true
        ;;

        -U|--uninstall)
            clean_up
        ;;

        *)
            echo "Invalid argument '$1'!"
            exit
        ;;
    esac
fi

########################

### MAIN ###

if [[ $SAFETY_MODE == "false" ]]
then
    echo "Creating directory '/usr/local/lib/tui-todolist'"
    sleep 0.5
    sudo mkdir /usr/local/lib/tui-todolist
    echo " > Done!"
    sleep 0.5

    echo "Creating directory '~/.config/tui-todolist'"
    sleep 0.5
    sudo mkdir ~/.config/tui-todolist
    echo " > Done!"
    sleep 0.5

    echo "Creating directory '~/.local/share/tui-todolist'"
    sleep 0.5
    sudo mkdir ~/.local/share/tui-todolist
    echo " > Done!"
    sleep 0.5

    echo "Copy/pasting 'todolist_main.sh' into'/usr/local/lib/tui-todolist/'"
    sleep 0.5
    sudo cp todolist_main.sh /usr/local/lib/tui-todolist/todolist_main.sh
    echo " > Done!"
    sleep 0.5

    echo "Copy/pasting 'todolist_functions.sh' into'/usr/local/lib/tui-todolist/'"
    sleep 0.5
    sudo cp todolist_functions.sh /usr/local/lib/tui-todolist/todolist_functions.sh
    echo " > Done!"
    sleep 0.5

    echo "Copy/pasting 'config.json' into '~/.config/tui-todolist/'"
    sleep 0.5
    sudo cp config.json ~/.config/tui-todolist/config.json
    echo " > Done!"
    sleep 0.5

    echo "Copy/pasting 'bin/tui-todolist' into '/usr/local/bin/'"
    sleep 0.5
    sudo cp bin/tui-todolist /usr/local/bin/tui-todolist
    echo " > Done!"
    sleep 0.5

    for DEPENDENCY in "${DEPENDENCIES[@]}"
    do
        check_dependency $DEPENDENCY
    done

    echo "ALL DONE!"
elif [[ $SAFETY_MODE == "true" ]]
then
    read -p "Create directory '/usr/local/lib/tui-todolist'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Creating directory '/usr/local/lib/tui-todolist'"
        sleep 1
        sudo mkdir /usr/local/lib/tui-todolist
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    read -p "Create directory '~/.config/tui-todolist'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Creating directory '~/.config/tui-todolist'"
        sleep 1
        sudo mkdir ~/.config/tui-todolist
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    read -p "Create directory '~/.local/share/tui-todolist'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Creating directory '~/.local/share/tui-todolist'"
        sleep 1
        sudo mkdir ~/.local/share/tui-todolist
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    read -p "Copy/paste' todolist_main.sh' into '/usr/local/lib/tui-todolist/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Copy/pasting 'todolist_main.sh' into '/usr/local/lib/tui-todolist/'"
        sleep 1
        sudo cp todolist_main.sh /usr/local/lib/tui-todolist/todolist_main.sh
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    read -p "Copy/paste' 'todolist_functions.sh' into '/usr/local/lib/tui-todolist/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Copy/pasting 'todolist_functions.sh' into '/usr/local/lib/tui-todolist/'"
        sleep 1
        sudo cp todolist_functions.sh /usr/local/lib/tui-todolist/todolist_functions.sh
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    read -p "Copy/paste 'config.json' into '~/.config/tui-todolist/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Copy/pasting 'config.json' into '~/.config/tui-todolist/'"
        sleep 1
        chmod 666 config.json
        sudo cp config.json ~/.config/tui-todolist/config.json
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    read -p "Copy/paste 'bin/tui-todolist' into '/usr/local/bin/'? (Y/n) " confirm
    if [[ $confirm == "Y" ]]
    then
        echo "Copy/pasting 'bin/tui-todolist' into '/usr/bin/bin/'"
        sleep 1
        chmod +x bin/tui-todolist
        sudo cp bin/tui-todolist /usr/local/bin/tui-todolist
        echo " > Done!"
        sleep 1
    else
        echo "Aborting..."
        sleep 1
        clean_up
    fi

    echo
    for DEPENDENCY in "${DEPENDENCIES[@]}"
    do
        check_dependency $DEPENDENCY
    done

    echo "ALL DONE!"
fi
