#!/bin/bash
sleep 0.1

## Import functions
source ~/git/tui-todolist/todolist_functions.sh

### DECLARE ###

# Constants #
date=$(date +"%Y-%m-%d")
bold=$(tput bold)
normal=$(tput sgr0)
cursive=$(tput sitm)
TODO_FILE=~/.local/share/tui-todolist/todolist.txt
TRASHCAN_FILE=~/.local/share/tui-todolist/todolist_trashcan.txt
SHOW_STALLED_FILE=~/.config/tui-todolist/other/show_stalled.txt

# VARIABLES #
where=0
optionswhere=0
keywhere=0
viswhere=0
trashwhere=0
currentmode=main
needredraw=1
SHOW_STALLED=$(cat $SHOW_STALLED_FILE)

debug=0

## Settings
CONFIG_FILE=~/.config/tui-todolist/config.json
theme_setting="$(jq -r .theme $CONFIG_FILE)"
highlightcolor="$(jq -r .highlight_color $CONFIG_FILE)"
textcolor="$(jq -r .text_color $CONFIG_FILE)"
linecolor="$(jq -r .line_color $CONFIG_FILE)"
date_setting="$(jq -r .date $CONFIG_FILE)"
title_setting="$(jq -r .title $CONFIG_FILE)"
lines_setting="$(jq -r .lines $CONFIG_FILE)"

# ARRAYS #
todolist=()
trashcan=()

declare -A cursor=(
    ["main"]=0
    ["options"]=0
    ["keybindings"]=0
    ["visuals"]=0
    ["trashcan"]=0
)

optionsList=("Visuals" "Keybindings")

declare -A visuals=(
    ["Theme"]=""$theme_setting"0"
    ["Text color"]="White1"
    ["Highlight color"]="White2"
    ["Line color"]="White3"
    ["Date"]=""$date_setting"4"
    ["Title"]=""$title_setting"5"
    ["Lines"]=""$lines_setting"6"
)
visualsOrder=("Theme" "Text color" "Highlight color" "Line color" "Date" "Title" "Lines")

declare -A keybindings=( 
    ["Move up"]="W / ARROW UP0" 
    ["Move down"]="S / ARROW DOWN1" 
    ["New task"]="T2" 
    ["Change status/Confirm"]="SPACE / ENTER3" 
    ["Back/Cancel"]="ESCAPE4" 
    ["Remove"]="BACKSPACE5" 
    ["Trashcan"]="D6"
    ["Stall"]="Q7"
    ["Duplicate"]="V8"
    ["Rename/Recover"]="R9"
    )
keybindingsOrder=("Move up" "Move down" "New task" "Change status/Confirm" "Back/Cancel" "Remove" "Trashcan" "Stall" "Duplicate" "Rename/Recover")

### PRE-EXECUTION CHECKS ###
PKG_DEPENDENCIES=("figlet" "dialog")
DISTRO=$(cat /etc/os-release | grep ^NAME | sed 's/NAME="//; s/"$//')

for DEPENDENCY in "${PKG_DEPENDENCIES[@]}"
do
    check_dependency $DEPENDENCY
done

if [[ ! -d ~/.local/share/cli-todolist/ ]]
then
    mkdir ~/.local/share/cli-todolist/
fi

if [[ ! -d ~/.config/cli-todolist/ ]]
then
    mkdir ~/.config/cli-todolist/
fi



######################################################

### MAIN ###
trap 'handleResize' SIGWINCH


while true;
do
    currentmode=main
    tput civis
    draw "main" 0
    option=$(read_key)

    case $option in
        ## UP
        w|W|$'\e[A')
            draw "main" 0
            where=$(move_up "todolist" "$where")
        ;;

        ## DOWN
        s|S|$'\e[B')
            draw "main" 0
            where=$(move_down "todolist" "$where")
        ;;

        ## NEW
        t|T)
            currentmode=main
            tput cnorm

            draw "main" 1

            #read -p " ${bold}> New To-do:${normal} " new
            new=$(dialog --stdout --inputbox "New task:" 8 70)

            if [[ -n $new ]]
            then
                if [[ $new == "c" ]]
                then
                    :
                elif [[ $new == !* ]]
                then
                    todolist+=("! ${new:1}")
                    saveListToFile "todolist" "$TODO_FILE"
                    notify-send -t 2500 "To-Do-list" "Prio-task \"${new:1}\" was added!"
                elif [[ $new == \?* ]]
                then
                    todolist+=("? ${new:1}")
                    saveListToFile "todolist" "$TODO_FILE"
                    notify-send -t 2500 "To-Do-list" "Stalled task \"${new:1}\" was added!"
                else
                    todolist+=(" $new")
                    saveListToFile "todolist" "$TODO_FILE"
                    notify-send -t 2500 "To-Do-list" "Task \"$new\" was added!"
                fi
            fi
        ;; 

        ## STALL
        q|Q)
            draw "main" 0
            if [[ "${todolist[$where]}" == \?* ]]; 
            then
                todolist[$where]="${todolist[$where]:1}"
            else
                todolist[$where]="?${todolist[$where]}"
            fi
            ((where--))
            saveListToFile "todolist" "$TODO_FILE"
        ;;   

        ### hide/show stalled
        h|H)
            if [[ $SHOW_STALLED -eq 1 ]]
            then
                SHOW_STALLED=0
                echo "0" > $SHOW_STALLED_FILE
            else
                SHOW_STALLED=1
                echo "1" > $SHOW_STALLED_FILE
            fi
        ;;

        ## DUPLICATE
        v|V)
            todolist+=("${todolist[$where]}")
            saveListToFile "todolist" "$TODO_FILE"
        ;;    
        
        ## REMOVE
        $'\177')
            currentmode=main
            draw "main" 1
            read -n 1 -s -p " > Are you sure you want to remove task $(($where+1))?" confirmremove

            if [[ $confirmremove == "" ]]
            then
                trashcan+=("${todolist[$where]}")
                todolist=("${todolist[@]:0:$where}" "${todolist[@]:$(($where + 1))}") # overwrite array with elements before and after the element that is being removed, that way the indexes are correct again
                if [[ ! $where -eq 0 ]]
                then
                    ((where--))
                fi
            fi

            saveListToFile "todolist" "$TODO_FILE"
            saveListToFile "trashcan" "$TRASHCAN_FILE"
        ;;

        ## CLEAR LIST
        c|C)
            currentmode=main
            if [[ ! ${#todolist[@]} = 0 ]]
            then
                draw "main" 1
                read -n 1 -s -p " > Are you sure you want to clear the whole list?" clear

                if [[ $clear == "" ]]
                then
                    unset todolist
                    rm $TODO_FILE
                    notify-send -t 2500 "To-Do-list" "List was cleared!"
                fi
            fi

            where=0
        ;;

        ## EXIT
        e|E|$'\e')
            tput cnorm
            clear
            exit
        ;;

        ## PRIORITY
        p|P)
            if [[ ! "${todolist[$where]}" == \?* ]]
            then
                if [[ "${todolist[$where]}" == !* ]]
                then
                    todolist[$where]="${todolist[$where]:1}"
                else
                    todolist[$where]="!${todolist[$where]}"
                fi
                saveListToFile "todolist" "$TODO_FILE"
            fi
        ;;

        ## RENAME
        r|R)
            currentmode=main
            draw "main" 1
            tput cnorm

            if [[ ${todolist[$where]} == !* ]]
            then
                newname=$(dialog --stdout --inputbox "New task:" 8 70 "${todolist[$where]:2}")
            else
                newname=$(dialog --stdout --inputbox "New task:" 8 70 "${todolist[$where]:1}")
            fi

            if [[ -n $newname ]]
            then
                if [[ "${todolist[$where]}" == !* ]]
                then
                    todolist[$where]="! $newname"
                else
                    todolist[$where]=" $newname"
                fi
            fi

            saveListToFile "todolist" "$TODO_FILE"
        ;;

        ## TRASHCAN
        d|D)
            loop=1
            while [[ $loop -eq 1 ]];
            do
                currentmode=trashcan
                draw "trashcan"
                
                optiontrashcan=$(read_key)

                case $optiontrashcan in
                    ## UP
                    w|W|$'\e[A')
                        draw "trashcan"
                        trashwhere=$(move_up "trashcan" "$trashwhere")
                    ;;

                    ## DOWN
                    s|S|$'\e[B')
                        draw "trashcan"
                        trashwhere=$(move_down "trashcan" "$trashwhere")
                    ;;

                    ## RECOVER TASK
                    r|R)
                        todolist+=("${trashcan[$trashwhere]}")
                        trashcan=("${trashcan[@]:0:$trashwhere}" "${trashcan[@]:$(($trashwhere + 1))}") # overwrite array with elements before and after the element that is being removed, that way the indexes are correct again
                        saveListToFile "todolist" "$TODO_FILE"
                        saveListToFile "trashcan" "$TRASHCAN_FILE"
                    ;;

                    ## REMOVE
                    $'\177')
                        read -n 1 -s -p " > Are you sure you want to remove task $(($trashwhere+1)) from the trashcan?" confirmremove

                        if [[ $confirmremove == "" ]]
                        then
                            trashcan=("${trashcan[@]:0:$trashwhere}" "${trashcan[@]:$(($trashwhere + 1))}") # overwrite array with elements before and after the element that is being removed, that way the indexes are correct again
                            if [[ ! $trashwhere -eq 0 ]]
                            then
                                ((trashwhere--))
                            fi
                        fi
                        saveListToFile "trashcan" "$TRASHCAN_FILE"
                    ;;

                    ## EMPTY TRASHCAN
                    c|C)
                        if [[ ! ${#trashcan[@]} = 0 ]]
                        then
                            echo
                            read -n 1 -s -p " > Are you sure you want to empty the whole trashcan?" clear

                            if [[ $clear == "" ]]
                            then
                                unset trashcan
                                rm $TRASHCAN_FILE
                            fi
                        fi
                    ;;

                    ## DEBUG
                    0)
                        if [[ $debug -eq 0 ]]
                        then
                            debug=1
                        else
                            debug=0
                        fi
                    ;;

                    ## BACK
                    e|E|d|D|$'\e')
                        loop=0
                    ;;

                esac

            done
        ;;

        ## OPTIONS
        o|O)
                loop=1
                while [[ $loop -eq 1 ]];
                do
                    currentmode=options
                    draw "options"
                    
                    option2=$(read_key)

                    case $option2 in
                        ## UP
                        w|W|$'\e[A')
                            draw "options"
                            optionswhere=$(move_up "optionsList" "$optionswhere")
                        ;;

                        ## DOWN
                        s|S|$'\e[B')
                            draw "options"
                            optionswhere=$(move_down "optionsList" "$optionswhere")
                            ;;

                        ## SELECT
                        "")
                            if [[ ${optionsList[$optionswhere]} == "Keybindings" ]]
                            then
                                keywhere=0
                                keyloop=1
                                while [[ $keyloop -eq 1 ]];
                                do
                                    currentmode=visuals
                                    tput civis
                                    draw "keybindings"

                                    option3=$(read_key)

                                    case $option3 in
                                        ## UP
                                            w|W|$'\e[A')
                                                draw "keybindings"
                                                keywhere=$(move_up "keybindings" "$keywhere")
                                            ;;

                                        ## DOWN
                                            s|S|$'\e[B')
                                                draw "keybindings"
                                                keywhere=$(move_down "keybindings" "$keywhere")
                                            ;;

                                        ## SELECT
                                        "")
                                            tput cnorm
                                            echo
                                            read -r -n 1 -s -p " > Enter new keybinding: " newKey
                                            if [[ $newKey == $'\e' ]]
                                            then
                                                read -r -s -n 2 -t 0.1 restKey
                                                newKey+=$restKey
                                            fi
                                            
                                            newKey=${newKey^^}
                                            keybindings["${keybindingsOrder[$keywhere]}"]="$newKey$keywhere"
                                        ;;

                                        ## DEBUG
                                        0)
                                            if [[ $debug -eq 0 ]]
                                            then
                                                debug=1
                                            else
                                                debug=0
                                            fi
                                        ;;

                                        ## ESCAPE
                                        e|E|$'\e')
                                            keyloop=0
                                    esac
                                done
                            elif [[ ${optionsList[$optionswhere]} == "Visuals" ]]
                            then
                                viswhere=0
                                visloop=1
                                while [[ $visloop -eq 1 ]];
                                do
                                    currentmode=options
                                    tput civis
                                    draw "visuals"

                                    option4=$(read_key)

                                    case $option4 in
                                        ## UP
                                        w|W|$'\e[A')
                                            draw "visuals"
                                            viswhere=$(move_up "visuals" "$viswhere")
                                        ;;

                                        ## DOWN
                                        s|S|$'\e[B')
                                            draw "visuals"
                                            viswhere=$(move_down "visuals" "$viswhere")
                                        ;;

                                        ## SELECT
                                        "")
                                            case "${visualsOrder[$viswhere]}" in
                                                Theme)
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *Default*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Minimal$viswhere"
                                                            visuals["Date"]="Off4"
                                                            change_setting "date" "Off"
                                                            visuals["Title"]="Off5"
                                                            change_setting "title" "Off"
                                                            visuals["Lines"]="Off6"
                                                            change_setting "lines" "Off"
                                                            change_setting "theme" "Minimal"
                                                        ;;

                                                        *Minimal*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Default$viswhere"
                                                            visuals["Date"]="On4"
                                                            change_setting "date" "On"
                                                            visuals["Title"]="On5"
                                                            change_setting "title" "On"
                                                            visuals["Lines"]="On6"
                                                            change_setting "lines" "On"

                                                            change_setting "theme" "Default"
                                                        ;;

                                                        *Custom*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Default$viswhere"
                                                            visuals["Text color"]="White1"
                                                            textcolor=37
                                                            change_setting "text_color" "37"
                                                            visuals["Highlight color"]="White2"
                                                            highlightcolor=47
                                                            change_setting "highlight_color" "47"
                                                            visuals["Date"]="On4"
                                                            change_setting "date" "On"
                                                            visuals["Title"]="On5"
                                                            change_setting "title" "On"
                                                            visuals["Lines"]="On6"
                                                            change_setting "lines" "On"
                                                            visuals["Line color"]="White3"
                                                            linecolor=37
                                                            change_setting "line_color" "37"
                                                            
                                                            change_setting "theme" "Default"
                                                    esac
                                                ;;
                                                "Text color")
                                                    visuals["Theme"]="Custom0"
                                                    change_setting "theme" "Custom"
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *White*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Black$viswhere"
                                                            textcolor=30
                                                            change_setting "text_color" "30"
                                                        ;;

                                                        *Black*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Red$viswhere"
                                                            textcolor=31
                                                            change_setting "text_color" "31"
                                                        ;;

                                                        *Red*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Green$viswhere"
                                                            textcolor=32
                                                            change_setting "text_color" "32"
                                                        ;;

                                                        *Green*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Yellow$viswhere"
                                                            textcolor=33
                                                            change_setting "text_color" "33"
                                                        ;;

                                                        *Yellow*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Blue$viswhere"
                                                            textcolor=34
                                                            change_setting "text_color" "34"
                                                        ;;

                                                        *Blue*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Magenta$viswhere"
                                                            textcolor=35
                                                            change_setting "text_color" "35"
                                                        ;;

                                                        *Magenta*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Cyan$viswhere"
                                                            textcolor=36
                                                            change_setting "text_color" "36"
                                                        ;;

                                                        *Cyan*)
                                                            visuals["${visualsOrder[$viswhere]}"]="White$viswhere"
                                                            textcolor=37
                                                            change_setting "text_color" "37"
                                                        ;;
                                                    esac
                                                ;;

                                                "Highlight color")
                                                    visuals["Theme"]="Custom0"
                                                    change_setting "theme" "Custom"
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *White*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Red$viswhere"
                                                            highlightcolor=41
                                                            change_setting "highlight_color" "41"
                                                        ;;
                                                        
                                                        *Red*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Green$viswhere"
                                                            highlightcolor=42
                                                            change_setting "highlight_color" "42"
                                                        ;;

                                                        *Green*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Yellow$viswhere"
                                                            highlightcolor=43
                                                            change_setting "highlight_color" "43"
                                                        ;;

                                                        *Yellow*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Blue$viswhere"
                                                            highlightcolor=44
                                                            change_setting "highlight_color" "44"
                                                        ;;

                                                        *Blue*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Magenta$viswhere"
                                                            highlightcolor=45
                                                            change_setting "highlight_color" "45"
                                                        ;;

                                                        *Magenta*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Cyan$viswhere"
                                                            highlightcolor=46
                                                            change_setting "highlight_color" "46"
                                                        ;;

                                                        *Cyan*)
                                                            visuals["${visualsOrder[$viswhere]}"]="White$viswhere"
                                                            highlightcolor=47
                                                            change_setting "highlight_color" "47"
                                                        ;;
                                                    esac
                                                ;;
                                                Date)
                                                    visuals["Theme"]="Custom0"
                                                    change_setting "theme" "Custom"
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *On*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Off$viswhere"
                                                            change_setting "date" "Off"
                                                        ;;
                                                        
                                                        *Off*)
                                                            visuals["${visualsOrder[$viswhere]}"]="On$viswhere"
                                                            change_setting "date" "On"
                                                        ;;
                                                    esac
                                                ;;
                                                Title)
                                                    visuals["Theme"]="Custom0"
                                                    change_setting "theme" "Custom"
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *On*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Off$viswhere"
                                                            change_setting "title" "Off"
                                                        ;;
                                                        
                                                        *Off*)
                                                            visuals["${visualsOrder[$viswhere]}"]="On$viswhere"
                                                            change_setting "title" "On"
                                                        ;;
                                                    esac
                                                ;;
                                                Lines)
                                                    visuals["Theme"]="Custom0"
                                                    change_setting "theme" "Custom"
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *On*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Off$viswhere"
                                                            change_setting "lines" "Off"
                                                        ;;
                                                        
                                                        *Off*)
                                                            visuals["${visualsOrder[$viswhere]}"]="On$viswhere"
                                                            change_setting "lines" "On"
                                                        ;;
                                                    esac
                                                ;;
                                                "Line color")
                                                    visuals["Theme"]="Custom0"
                                                    change_setting "theme" "Custom"
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *White*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Black$viswhere"
                                                            linecolor=30
                                                            change_setting "line_color" "30"
                                                        ;;

                                                        *Black*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Red$viswhere"
                                                            linecolor=31
                                                            change_setting "line_color" "31"
                                                        ;;

                                                        *Red*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Green$viswhere"
                                                            linecolor=32
                                                            change_setting "line_color" "32"
                                                        ;;

                                                        *Green*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Yellow$viswhere"
                                                            linecolor=33
                                                            change_setting "line_color" "33"
                                                        ;;

                                                        *Yellow*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Blue$viswhere"
                                                            linecolor=34
                                                            change_setting "line_color" "34"
                                                        ;;

                                                        *Blue*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Magenta$viswhere"
                                                            linecolor=35
                                                            change_setting "line_color" "35"
                                                        ;;

                                                        *Magenta*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Cyan$viswhere"
                                                            linecolor=36
                                                            change_setting "line_color" "36"
                                                        ;;

                                                        *Cyan*)
                                                            visuals["${visualsOrder[$viswhere]}"]="White$viswhere"
                                                            linecolor=37
                                                            change_setting "line_color" "37"
                                                        ;;
                                                    esac
                                                ;;
                                            esac
                                        ;;

                                        ## DEBUG
                                        0)
                                            if [[ $debug -eq 0 ]]
                                            then
                                                debug=1
                                            else
                                                debug=0
                                            fi
                                        ;;

                                        ## ESCAPE
                                        e|E|$'\e')
                                            visloop=0
                                    esac
                                done
                            fi
                        ;;

                        ## DEBUG
                        0)
                            if [[ $debug -eq 0 ]]
                             then
                                debug=1
                            else
                                debug=0
                            fi
                        ;;

                        ## ESCAPE
                        e|E|$'\e')
                            where=0
                            loop=0
                        ;;
                    esac
                done
        ;;

        ## DONE
        "")
            if [[ -f $TODO_FILE ]]
            then
                #printMenu
                draw "main" 0
                if [[ ! "${todolist[$where]}" == \?* ]]
                then
                    if [[ "${todolist[$where]}" == *#done  ]] # check if element is unmarked and mark if unmarked or unmark if marked
                    then
                        todolist[$where]="${todolist[$where]%#done}"
                    else
                        todolist[$where]="${todolist[$where]}#done"
                    fi
                    saveListToFile "todolist" "$TODO_FILE"
                fi
            fi
        ;;

        ## DEBUG
        0)
            if [[ $debug -eq 0 ]]
            then
                debug=1
            else
                debug=0
            fi
        ;;
    esac
done
