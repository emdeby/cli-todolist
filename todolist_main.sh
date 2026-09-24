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
TODO_FILE=~/.local/share/cli-todolist/todolist.txt
TRASHCAN_FILE=~/.local/share/cli-todolist/todolist_dev/todolist_trashcan.txt
SHOW_STALLED_FILE=~/.config/cli-todolist/other/show_stalled.txt

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
theme_file=~/.config/cli-todolist/settings/theme.txt
theme_setting="$(cat $theme_file)"
highlightcolor_file=~/.config/cli-todolist/settings/highlight_color.txt
highlightcolor="$(cat $highlightcolor_file)"
textcolor_file=~/.config/cli-todolist/settings/text_color.txt
textcolor="$(cat $textcolor_file)"
window_size_sway=~/.config/cli-todolist/settings/window_size_sway.txt
window_size_SAFE=~/.config/cli-todolist/settings/window_size_SAFE.txt
date_file=~/.config/cli-todolist/settings/date.txt
date_setting="$(cat $date_file)"
title_file=~/.config/cli-todolist/settings/title.txt
title_setting="$(cat $title_file)"
lines_file=~/.config/cli-todolist/settings/lines.txt
lines_setting="$(cat $lines_file)"
linecolor_file=~/.config/cli-todolist/settings/lines_color.txt
linecolor="$(cat $linecolor_file)"
backgroundcolor_sway=~/.config/cli-todolist/settings/background_color_sway.txt
background_colorcode=~/.config/cli-todolist/settings/background_color.txt

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
    ["Date"]=""$date_setting"3"
    ["Title"]=""$title_setting"4"
    ["Lines"]=""$lines_setting"5"
    ["Line color"]="White6"
)
visualsOrder=("Theme" "Text color" "Highlight color" "Date" "Title" "Lines" "Line color")

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
                                                            visuals["Text color"]="White1"
                                                            textcolor=37
                                                            echo "37" > $textcolor_file
                                                            visuals["Highlight color"]="White3"
                                                            highlightcolor=47
                                                            echo "47" > $highlightcolor_file
                                                            visuals["Date"]="Off4"
                                                            echo "Off" > $date_file
                                                            visuals["Title"]="Off5"
                                                            echo "Off" > $title_file
                                                            visuals["Lines"]="Off6"
                                                            echo "Off" > $lines_file
                                                            visuals["Line color"]="White7"
                                                            textcolor=37
                                                            echo "37" > $linecolor_file

                                                            echo "Minimal" > $theme_file
                                                        ;;

                                                        *Minimal*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Default$viswhere"
                                                            visuals["Text color"]="White1"
                                                            textcolor=37
                                                            echo "37" > $textcolor_file
                                                            visuals["Highlight color"]="White3"
                                                            highlightcolor=47
                                                            echo "47" > $highlightcolor_file
                                                            visuals["Date"]="On4"
                                                            echo "On" > $date_file
                                                            visuals["Title"]="On5"
                                                            echo "On" > $title_file
                                                            visuals["Lines"]="On6"
                                                            echo "On" > $lines_file
                                                            visuals["Line color"]="White7"
                                                            textcolor=37
                                                            echo "37" > $linecolor_file

                                                            echo "Default" > $theme_file
                                                        ;;

                                                        *Custom*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Default$viswhere"
                                                            visuals["Text color"]="White1"
                                                            textcolor=37
                                                            echo "37" > $textcolor_file
                                                            visuals["Highlight color"]="White3"
                                                            highlightcolor=47
                                                            echo "47" > $highlightcolor_file
                                                            visuals["Text color"]="White1"
                                                            textcolor=37
                                                            echo "37" > $textcolor_file
                                                            visuals["Date"]="On4"
                                                            echo "On" > $date_file
                                                            visuals["Title"]="On5"
                                                            echo "On" > $title_file
                                                            visuals["Lines"]="On6"
                                                            echo "On" > $lines_file
                                                            visuals["Line color"]="White7"
                                                            textcolor=37
                                                            echo "37" > $linecolor_file

                                                            echo "Default" > $theme_file
                                                    esac
                                                ;;
                                                "Text color")
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *White*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Black$viswhere"
                                                            textcolor=30
                                                            echo "30" > $textcolor_file
                                                        ;;

                                                        *Black*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Red$viswhere"
                                                            textcolor=31
                                                            echo "31" > $textcolor_file
                                                        ;;

                                                        *Red*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Green$viswhere"
                                                            textcolor=32
                                                            echo "32" > $textcolor_file
                                                        ;;

                                                        *Green*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Yellow$viswhere"
                                                            textcolor=33
                                                            echo "33" > $textcolor_file
                                                        ;;

                                                        *Yellow*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Blue$viswhere"
                                                            textcolor=34
                                                            echo "34" > $textcolor_file
                                                        ;;

                                                        *Blue*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Magenta$viswhere"
                                                            textcolor=35
                                                            echo "35" > $textcolor_file
                                                        ;;

                                                        *Magenta*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Cyan$viswhere"
                                                            textcolor=36
                                                            echo "36" > $textcolor_file
                                                        ;;

                                                        *Cyan*)
                                                            visuals["${visualsOrder[$viswhere]}"]="White$viswhere"
                                                            textcolor=37
                                                            echo "37" > $textcolor_file
                                                        ;;
                                                    esac
                                                ;;

                                                "Highlight color")
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *White*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Red$viswhere"
                                                            highlightcolor=41
                                                            echo "41" > $highlightcolor_file
                                                        ;;
                                                        
                                                        *Red*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Green$viswhere"
                                                            highlightcolor=42
                                                            echo "42" > $highlightcolor_file
                                                        ;;

                                                        *Green*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Yellow$viswhere"
                                                            highlightcolor=43
                                                            echo "43" > $highlightcolor_file
                                                        ;;

                                                        *Yellow*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Blue$viswhere"
                                                            highlightcolor=44
                                                            echo "44" > $highlightcolor_file
                                                        ;;

                                                        *Blue*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Magenta$viswhere"
                                                            highlightcolor=45
                                                            echo "45" > $highlightcolor_file
                                                        ;;

                                                        *Magenta*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Cyan$viswhere"
                                                            highlightcolor=46
                                                            echo "46" > $highlightcolor_file
                                                        ;;

                                                        *Cyan*)
                                                            visuals["${visualsOrder[$viswhere]}"]="White$viswhere"
                                                            highlightcolor=47
                                                            echo "47" > $highlightcolor_file
                                                        ;;
                                                    esac
                                                ;;
                                                Date)
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *On*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Off$viswhere"
                                                            echo "Off" > $date_file
                                                        ;;
                                                        
                                                        *Off*)
                                                            visuals["${visualsOrder[$viswhere]}"]="On$viswhere"
                                                            echo "On" > $date_file
                                                        ;;
                                                    esac
                                                ;;
                                                Title)
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *On*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Off$viswhere"
                                                            echo "Off" > $title_file
                                                        ;;
                                                        
                                                        *Off*)
                                                            visuals["${visualsOrder[$viswhere]}"]="On$viswhere"
                                                            echo "On" > $title_file
                                                        ;;
                                                    esac
                                                ;;
                                                Lines)
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *On*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Off$viswhere"
                                                            echo "Off" > $lines_file
                                                        ;;
                                                        
                                                        *Off*)
                                                            visuals["${visualsOrder[$viswhere]}"]="On$viswhere"
                                                            echo "On" > $lines_file
                                                        ;;
                                                    esac
                                                ;;
                                                "Line color")
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    case ${visuals["${visualsOrder[$viswhere]}"]} in
                                                        *White*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Black$viswhere"
                                                            linecolor=30
                                                            echo "30" > $linecolor_file
                                                        ;;

                                                        *Black*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Red$viswhere"
                                                            linecolor=31
                                                            echo "31" > $linecolor_file
                                                        ;;

                                                        *Red*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Green$viswhere"
                                                            linecolor=32
                                                            echo "32" > $linecolor_file
                                                        ;;

                                                        *Green*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Yellow$viswhere"
                                                            linecolor=33
                                                            echo "33" > $linecolor_file
                                                        ;;

                                                        *Yellow*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Blue$viswhere"
                                                            linecolor=34
                                                            echo "34" > $linecolor_file
                                                        ;;

                                                        *Blue*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Magenta$viswhere"
                                                            linecolor=35
                                                            echo "35" > $linecolor_file
                                                        ;;

                                                        *Magenta*)
                                                            visuals["${visualsOrder[$viswhere]}"]="Cyan$viswhere"
                                                            linecolor=36
                                                            echo "36" > $linecolor_file
                                                        ;;

                                                        *Cyan*)
                                                            visuals["${visualsOrder[$viswhere]}"]="White$viswhere"
                                                            linecolor=37
                                                            echo "37" > $linecolor_file
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
