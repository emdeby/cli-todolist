#!/bin/bash
# FUNCTIONS 
saveListToFile() {
    declare -n list="$1"
    file="$2"
    printf "%s\n" "${list[@]}" > $file
}

reorderList() {
    declare -n list="$1"
    local prioList=()
    local normalList=()
    local stallList=()
    stalled_tasks=0
    
    for i  in "${!list[@]}"
    do
        if [[ "${list[$i]}" == !* ]]
        then
            prioList+=("${list[$i]}")
        elif [[ "${list[$i]}" == \?* ]]
        then
            stallList+=("${list[$i]}")
            ((stalled_tasks++))
        else
            normalList+=("${list[$i]}")
        fi
    done

    if [[ ${#prioList[@]} = 0 && ${#stallList[@]} = 0 ]]
    then
        list=("${normalList[@]}")
    else
        list=("${prioList[@]}" "${normalList[@]}" "${stallList[@]}")
    fi
}

calcSpaces(){
    twidth=$(tput cols)
    line="$1"
    linelength=${#line}
    if [[ $2 -eq 1 ]]
    then
        ((linelength++))
    fi  
    spacesneeded=$(( twidth - linelength ))
    padding=$(printf '%*s' "$spacesneeded")
    printf '%s%s' "$line" "$padding"
}

highlight() {
    local line="$1"
    local isbold=$2
    local istodo=$3
    local iscursive=$4
    local isdone=0
    local width=$(tput cols)

    if [[ "$line" == *#done ]]
    then
        isdone=1
        line="${line:0:-5}"
    fi


    linelength=${#line}
    if [[ $linelength -gt $width ]]
    then
        spacesneeded=$(( 2 * width - linelength ))
    else
        spacesneeded=$(( width - linelength ))
    fi
    padding=$(printf '%*s' "$spacesneeded")

    if [[ $isbold -eq 1 ]]
    then
        if [[ $isdone -eq 1 && $istodo -eq 1 ]]
        then
            printf '\e[9m\e['$highlightcolor'm\e[30m%s\e[0m\n' "${bold}${line}${padding}${normal}"
        else
            printf '\e['$highlightcolor'm\e[30m%s\e[0m\n' "${bold}${line}${padding}${normal}"
        fi
    elif [[ $iscursive -eq 1 ]]
    then
        printf '\e['$highlightcolor'm\e[30m%s\e[0m\n' "${cursive}${line}${padding}${normal}"
    else
        if [[ $isdone -eq 1 && $istodo -eq 1 ]]
        then
            printf '\e[9m\e['$highlightcolor'm\e[30m%s%s\e[0m\n' "$line" "$padding"
        else
            printf '\e['$highlightcolor'm\e[30m%s%s\e[0m\n' "$line" "$padding"
        fi
    fi
}

highlightElse() {
    line="$1"
    linelength=${#line}
    spacesneeded=$(( $(tput cols) - linelength ))
    padding=$(printf '%*s' "$spacesneeded")
    printf '\e['$highlightcolor'm\e[30m%s%s\e[0m\n' "$line" "$padding"
}

draw() {
    case $1 in
        main)
            printMenu "$where" "$2"
        ;;

        mainspecial)
            printMenuSpecial
        ;;

        options)
            printOptions "$optionswhere"
        ;;

        keybindings)
            printSuboption "keybindings" "keybindingsOrder" "$keywhere" "Keybindings"
        ;;

        visuals)
            printSuboption "visuals" "visualsOrder" "$viswhere" "Visuals"        
        ;;

        trashcan)
            printTrashcan "$trashwhere"
        ;;
    esac
}

handleResize() {
    draw "$currentmode"
}

printMAJOR() {
    ## USAGE: e.g.: printMAJOR "[TEXT]" "BOLD" "STRIKETHROUGH"
    ## future: instead of fixed positions for styling parameters, just iterate through all parameters and check
    ## if there's e.g. "bold". Also: if there's e.g. two parameters "bold", then ignore second one
    ## In the future this function shouldn't rely on parameters given to it for the formatting. The function itself
    ## should parse the provided text for the styling syntax (e.g. ! for prio or #done for finished tasks etc.)

    local line="$1"
    shift
    
    local format="\e['$textcolor'm"
    local format2=""

    ## PADDING
    local linelength=${#line}
    local spacesneeded=0
    local width=$(tput cols)
    if [[ $linelength -gt $width ]]
    then
        spacesneeded=$(( 2 * width - linelength ))
    else
        spacesneeded=$(( width - linelength ))
    fi
    local padding=$(printf '%*s' "$spacesneeded")
    line+=$padding

    ## FORMAT
    for arg in "$@"
    do
        if [[ $arg == "highlight" ]]
        then
            format="\e["$highlightcolor"m\e[30m"
        fi

        if [[ $arg == "strikethrough" ]]
        then
            format+="\e[9m"
        fi

        if [[ $arg == "bold" ]]
        then
            format2="$(tput bold)"
        fi

        if [[ $arg == "cursive" ]]
        then
            format2+=$(tput sitm)
        fi
    done

    printf ''$format'%s%s\e[0m\n' "${format2}$line${normal}"
}

printMAJOR2() {
    ## USAGE: e.g.: printMAJOR2 "[PREFIX e.g. numbering]" "[TEXT]" "BOLD" "STRIKETHROUGH"
    ## future: instead of fixed positions for styling parameters, just iterate through all parameters and check
    ## if there's e.g. "bold". Also: if there's e.g. two parameters "bold", then ignore second one
    ## In the future this function shouldn't rely on only parameters given to it for the formatting. The function itself
    ## should parse the provided text for the styling syntax (e.g. ! for prio or #done for finished tasks etc.)

    local prefix="$1"
    local line="$2"
    shift
    shift
    
    local format="\e["$textcolor"m"
    local format2=""
    local isdone=0
    local isprio=0

    ## PRE-FORMAT
    if [[ "$line" == *#done ]]
    then
        isdone=1
        line="${line:0:-5}"
    fi

    if [[ "$line" = !* ]]
    then
        isprio=1
        line="${line:1}"
    fi

    if [[ ! "$prefix" == "none" ]]
    then
        line="$prefix$line"
    fi

    ## PADDING
    local linelength=${#line}
    local spacesneeded=0
    local width=$(tput cols)
    if [[ $linelength -gt $width ]]
    then
        spacesneeded=$(( 2 * width - linelength ))
    else
        spacesneeded=$(( width - linelength ))
    fi
    local padding=$(printf '%*s' "$spacesneeded")
    line+=$padding

    ## STYLING
    ### parameter styling
    for arg in "$@"
    do
        if [[ $arg == "highlight" ]]
        then
            format="\e["$highlightcolor"m\e[30m"
        fi

        if [[ $arg == "strikethrough" ]]
        then
            format+="\e[9m"
        fi

        if [[ $arg == "bold" || $isprio -eq 1 ]]
        then
            format2="$(tput bold)"
        fi

        if [[ $arg == "cursive" ]]
        then
            format2+=$(tput sitm)
        fi
    done
    
    ### syntax styling
    if [[ $isdone -eq 1 ]]
    then
        format+="\e[9m"
    fi

    if [[ $isprio -eq 1 ]]
    then
        format2="$(tput bold)"
    fi

    printf ''$format'%s%s\e[0m\n' "${format2}$line${normal}"
}

printTrashcan() {
    local printGapPrio=1
    local printGapStall=1
    local noPrio=1
    local noStall=1
    local numbering=1

    unset prioTrashcan
    unset normalTrashcan

    if [[ -f $TRASHCAN_FILE ]]
    then
        mapfile -t trashcan < $TRASHCAN_FILE
    fi

    reorderList "trashcan"

    clear
    
    if [[ ${visuals["Title"]:0:-1} == "On" ]]
    then
        figlet " TRASHCAN"
    fi

    if [[ ${visuals["Lines"]:0:-1} == "On" ]]
    then
        printLine
    fi

    highlightElse " To-Do > Trashcan"
    echo

    if [[ ${#trashcan[@]} = 0 ]]
    then
        printEmpty
    else    
        for i in "${!trashcan[@]}"
        do
            if [[ "${trashcan[$i]}" == !* ]] # if prio
            then
                noPrio=0

                if [[ $i -eq $1 ]] # highlight
                then
                    highlight " $numbering. ${trashcan[$i]:1}" "1" "0" "0"
                else # no highlight
                    if [[ "${trashcan[$i]}" == *#done ]]
                    then
                        printf '\e['$textcolor'm%s\e[0m\n' "${bold} $(($numbering)). ${trashcan[$i]:1:-5}${normal}"
                    else
                        printf '\e['$textcolor'm%s\e[0m\n' "${bold} $(($numbering)). ${trashcan[$i]:1}${normal}"
                    fi
                fi    
                ((numbering++))
            elif [[ ! "${trashcan[$i]}" == !* && ! "${trashcan[$i]}" == \?*  ]] # if normal
            then
                if [[ $printGap == "1" && $noPrio == "0" ]]
                then
                    echo
                    printGap=0
                fi

                if [[ $i -eq $1 ]] # highlight
                then
                    highlight " $numbering. ${trashcan[$i]}" "0" "0" "0"
                else # no highlight
                    if [[ "${trashcan[$i]}" == *#done ]]
                    then
                        printf '\e['$textcolor'm%s\e[0m\n' " $(($numbering)). ${trashcan[$i]:0:-5}"
                    else
                        printf '\e['$textcolor'm%s\e[0m\n' " $(($numbering)). ${trashcan[$i]}"
                    fi
                fi
                ((numbering++))
            elif [[ "${trashcan[$i]}" == \?* ]] # if stalled
            then
                noPrio=0

                if [[ $i -eq $1 ]] # highlight
                then
                    highlight " $numbering. ${trashcan[$i]:1}" "0" "0" "0"
                else # no highlight
                    if [[ "${trashcan[$i]}" == *#done ]]
                    then
                        printf '\e['$textcolor'm%s\e[0m\n' " $(($numbering)). ${trashcan[$i]:1:-5}"
                    else
                        printf '\e['$textcolor'm%s\e[0m\n' " $(($numbering)). ${trashcan[$i]:1}"
                    fi
                fi    
                ((numbering++))
            fi    
        done 
    fi

    echo
    
    if [[ ${visuals["Lines"]:0:-1} == "On" ]]
    then
        printLine
    fi

    ## DEBUG
    if [[ $debug -eq  1 ]]
    then
        printDebug
    fi
}

printSuboption() {
    declare -n optionList="$1"
    declare -n listOrder="$2"
    local cursor="$3"
    local text="$4"

    clear
    
    if [[ ${visuals["Title"]:0:-1} == "On" ]]
    then
        figlet " ${text^^}"
    fi
    
    if [[ ${visuals["Lines"]:0:-1} == "On" ]]
    then
        printLine
    fi

    highlightElse " To-Do > Options > $text"
    echo

    for i in "${listOrder[@]}"
    do
        line="$i[${optionList[$i]}]"
        linelength=${#line}
        spacesneeded=$(( $(tput cols) - linelength ))
        padding=$(printf '%*s' "$spacesneeded")

        if [[ ${optionList[$i]} == *"$cursor" ]]
        then
            printf '\e['$highlightcolor'm\e[30m%s%s%s\e[0m\n' "$i" "$padding " "${bold}[${optionList[$i]:0:-1}]${normal}"
        else
            printf '\e['$textcolor'm%s%s%s\e[0m\n' "$i" "$padding " "${bold}[${optionList[$i]:0:-1}]${normal}"
        fi
    done

    ## DEBUG
    if [[ $debug -eq  1 ]]
    then
        printDebug
    fi
}

printOptions() {
    clear
    
    if [[ ${visuals["Title"]:0:-1} == "On" ]]
    then
        figlet " OPTIONS"
    fi

    if [[ ${visuals["Lines"]:0:-1} == "On" ]]
    then
        printLine
    fi

    highlightElse " To-Do > Options"
    echo
    for i in "${!optionsList[@]}"
    do
        if [[ $i -eq $1 ]]
        then
            highlightElse " > ${optionsList[$i]}"
        else
            printf '\e['$textcolor'm%s\e[0m\n' " > ${optionsList[$i]}"
        fi
    done

    ## DEBUG
    if [[ $debug -eq  1 ]]
    then
        printDebug
    fi
}

printListNEW() {
    ## this function should combine the printList and printTrashcan function 
    ## because they are nearly the same
    :
}

printList() {
    local printGapPrio=1
    local printGapStall=1
    local noPrio=1
    local noStall=1
    local numbering=1

    for i in "${!todolist[@]}"
    do
        if [[ "${todolist[$i]}" == !* ]] # if prio
        then
            noPrio=0

            if [[ $i -eq $1 ]]  # highlight
            then
                #highlight " $(($numbering)). ${todolist[$i]:1}" "1" "1" "0"
                printMAJOR2 " $(($numbering)). " "${todolist[$i]}" "highlight"
            else # no highlight
                printMAJOR2 " $(($numbering)). " "${todolist[$i]}"
            fi

            ((numbering++))
        elif [[ ! "${todolist[$i]}" == !* && ! "${todolist[$i]}" == \?* ]] # if normal
        then
            if [[ $printGapPrio == "1" && $noPrio == "0" ]]
            then
                echo
                printGapPrio=0
            fi

            if [[ $i -eq $1 ]] # highlight
            then
                #highlight " $(($numbering)). ${todolist[$i]}" "0" "1" "0"
                printMAJOR2 " $(($numbering)). " "${todolist[$i]}" "highlight"
            else # no highlight
                printMAJOR2 " $(($numbering)). " "${todolist[$i]}"
            fi

            ((numbering++))
        elif [[ "${todolist[$i]}" == \?* && $SHOW_STALLED -eq 1 ]] # if stall
        then
            noStall=0

            if [[ $printGapStall == "1" && $noStall == "0" ]]
            then
                echo
                echo " ----"
                printGapStall=0
            fi

            if [[ $i -eq $1 ]]  # highlight
            then
                if [[ "${todolist[$i]}" == \?!* ]]
                then
                    highlight " $(($numbering)). ${todolist[$i]:2}" "0" "1" "1"
                else
                    highlight " $(($numbering)). ${todolist[$i]:1}" "0" "1" "1"
                fi
            else # no highlight
                if [[ "${todolist[$i]}" == \?!* ]]
                then
                    printf '\e['$textcolor'm%s\e[0m\n' "${cursive}${bold} $(($numbering)). ${todolist[$i]:2}${normal}"
                else
                    printf '\e['$textcolor'm%s\e[0m\n' "${cursive} $(($numbering)). ${todolist[$i]:1}${normal}"
                fi
            fi
            ((numbering++))
        fi
    done 
}

printMenu() {
    unset prioList
    unset normalList
    local nohighlight=$2

    if [[ -f $TODO_FILE ]]
    then
        mapfile -t todolist < $TODO_FILE
    fi

    clear

    if [[ ${visuals["Date"]} == *"On"* ]]
    then
        ## Center date
        twidth=$(tput cols)
        figlet "$date" | while IFS= read -r line; do
            linelength=${#line}
            spacesneeded=$(( (twidth - linelength) / 2 ))
            padding=$(printf '%*s' "$spacesneeded")
            printf  '%s%s\n' "$padding" "$line"
        done
    fi

    if [[ ${visuals["Lines"]:0:-1} == "On" ]]
    then
        printLine
    fi

    echo

    if [[ ${#todolist[@]} = 0 ]]
    then
        printEmpty
    else
        reorderList "todolist"
        printList "$where" "$nohighlight"
    fi

    if [[ $SHOW_STALLED -eq 0 ]]
    then
        echo
        echo " ----"
        printf '\e['$textcolor'm%s\e[0m\n' " ${cursive}"$stalled_tasks" stalled tasks hidden...${normal}"
    fi

    echo
    
    if [[ ${visuals["Lines"]:0:-1} == "On" ]]
    then
        printLine
    fi

    ## DEBUG
    if [[ $debug -eq  1 ]]
    then
        printDebug
    fi
}

printEmpty() {
    twidth=$(tput cols)
    line="E M P T Y"
    linelength=${#line}
    spacesneeded=$(( (twidth - linelength) / 2 ))
    padding=$(printf '%*s' "$spacesneeded")
    printf  '%s%s%s\n' "$padding" "${bold}$line${normal}" "$padding"
}

printLine() {
    printf  '%*s\n' "$(tput cols)" '' | tr ' ' '-'
}

printDebug() {
    echo
    echo "---- DEBUG ----"
    echo "where: $where"
    echo "trashwere: $trashwhere"
    echo "optionswhere: $optionswhere"
    echo "keywhere: $keywhere"
    echo "viswhere: $vishwere"
    echo "winwhere: $winwhere"
    echo "Width: $(tput cols)" 
    echo "Height: $(tput lines)"

}

read_key() {
    read -r -n 1 -s key
    if [[ $key == $'\e' ]]
    then
        read -r -s -n 2 -t 0.1 rest
        key+=$rest
    fi

    echo "$key"
}

move_up() {
    declare -n list="$1"
    local cursor="$2"
    
    if [[ $SHOW_STALLED -eq 1 ]]
    then
        ((cursor--))
        if [[ $cursor -lt 0 ]]
        then
            cursor=$((${#list[@]} -1 ))
        fi
    else
        ((cursor--))
        if [[ $cursor -lt 0 ]]
        then
            cursor=$((${#list[@]} -1 ))
            while [[ "${list[$cursor]}" == \?* ]]
            do
                ((cursor--))
            done
        fi
    fi

    echo "$cursor"
}

move_down() {
    declare -n list="$1"
    local cursor="$2"

    if [[ $SHOW_STALLED -eq 1 ]]
    then
        if [[ $cursor -lt $((${#list[@]} -1 )) ]]
        then
            ((cursor++))
        else
            cursor=0
        fi
    else
        ((cursor++))
        if [[ "${list[$cursor]}" == \?* ]]
        then
            while [[ "${list[$cursor]}" == \?* ]]
            do
                ((cursor++))
            done
            cursor=0
        fi
    fi

    echo "$cursor"
}

move_right() {
    # for navigations through multiple pages of tasks
}

move_left() {
    # for navigations through multiple pages of tasks 
}

log() {
    local text="$1"
    echo "[$(date +%D-%T)] $text" >> $log_file
}

#####
# one-task-one-file

printTasks() {
    numbering=1
    for file in "$tasksDir"*
    do
        printf '%s\n' " $numbering. $(sed -n '/^#+$/,/^#-$/ { /^#+$/d; /^#-$/d;p }' "$file")"
        ((numbering++))
    done
}

printDescription() {
    local file=$1
    
    sed -n '/^%+$/,/^%-$/ { /^%+$/d; /^%-$/d; p}' "$file"

}