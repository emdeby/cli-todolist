#!/bin/bash
sleep 0.1

### DECLARE ###

# VARIABLES #
date=$(date +"%Y-%m-%d")
bold=$(tput bold)
normal=$(tput sgr0)
cursive=$(tput sitm)
#bgwhite="\e[47m"
#bgnormal="\e[0m"
todo_file=~/.local/share/myutils/todolist_dev/todolist_dev.txt
todo_prev_file=~/.local/share/myutils/todolist_dev/todolist_prev_dev.txt
todo_backup_file=~/.local/share/myutils/todolist_dev/todolist_backup_dev.txt
trashcan_file=~/.local/share/myutils/todolist_dev/todolist_trashcan_dev.txt
log_file=~/.local/share/myutils/todolist_dev/todolist_log_dev.txt
vis_file=~/.local/share/myutils/todolist_dev/todolist_vis_dev.txt
tasksDir=~/.local/share/myutils/todolist_dev/tasks/
where=0
optionswhere=0
keywhere=0
viswhere=0
winwhere=0
trashwhere=0
currentmode=main
needredraw=1
show_stalled_file=~/.local/share/myutils/todolist/other/show_stalled.txt
show_stalled=$(cat $show_stalled_file)

debug=0

## Settings
theme_file=~/.local/share/myutils/todolist/settings/theme.txt
theme_setting="$(cat $theme_file)"
highlightcolor_file=~/.local/share/myutils/todolist/settings/highlight_color.txt
highlightcolor="$(cat $highlightcolor_file)"
textcolor_file=~/.local/share/myutils/todolist/settings/text_color.txt
textcolor="$(cat $textcolor_file)"
window_size_sway=~/.local/share/myutils/todolist/settings/window_size_sway.txt
window_size_SAFE=~/.local/share/myutils/todolist/settings/window_size_SAFE.txt
date_file=~/.local/share/myutils/todolist/settings/date.txt
date_setting="$(cat $date_file)"
title_file=~/.local/share/myutils/todolist/settings/title.txt
title_setting="$(cat $title_file)"
lines_file=~/.local/share/myutils/todolist/settings/lines.txt
lines_setting="$(cat $lines_file)"
linecolor_file=~/.local/share/myutils/todolist/settings/lines_color.txt
linecolor="$(cat $linecolor_file)"
backgroundcolor_sway=~/.local/share/myutils/todolist/settings/background_color_sway.txt
background_colorcode=~/.local/share/myutils/todolist/settings/background_color.txt

# ARRAYS #
todolist=()
trashcan=()

declare -A cursor=(
    ["main"]=0
    ["options"]=0
    ["keybindings"]=0
    ["visuals"]=0
    ["window"]=0
    ["trashcan"]=0
)

optionsList=("Keybindings" "Visuals" "Windowoptions")

declare -A keybindings=( 
    ["Move up"]="ARROW UP0" 
    ["Move down"]="ARROW DOWN1" 
    ["New task"]="T2" 
    ["Change status"]="SPACE3" 
    ["Confirm"]="ENTER4" 
    ["Back/Cancel"]="ESCAPE5" 
    ["Remove"]="BACKSPACE6" 
    ["Stall"]="Q7"
    ["Duplicate"]="V8"
    ["Rename/Recover"]="R9"
    )
keybindingsOrder=("Move up" "Move down" "New task" "Change status" "Confirm" "Back/Cancel" "Remove" "Stall" "Duplicate" "Rename/Recover")

declare -A visuals=(
    ["Theme"]=""$theme_setting"0"
    ["Text color"]="White1"
    ["Background color"]=""$(cat $background_colorcode)"2"
    ["Highlight color"]="White3"
    ["Date"]=""$date_setting"4"
    ["Title"]=""$title_setting"5"
    ["Lines"]=""$lines_setting"6"
    ["Line color"]="White7"
)
visualsOrder=("Theme" "Text color" "Background color" "Highlight color" "Date" "Title" "Lines" "Line color")

declare -A window=(
    ["Mode"]="Flexible0"
    ["Size"]="$(cat $window_size_SAFE)1"
    ["Position"]="Center2"
)
windowOrder=("Mode" "Size" "Position") 

# FUNCTIONS #
source ~/Desktop/Git/cli-todolist/todolist_dev_functions.sh

######################################################

### MAIN ###
trap 'handleResize' SIGWINCH

log "STARTED" >> $log_file


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
            log "Trying to add \"$new\"..."

            if [[ -n $new ]]
            then
                if [[ $new == "c" ]]
                then
                    :
                elif [[ $new == !* ]]
                then
                    todolist+=("! ${new:1}")
                    saveListToFile "todolist" "$todo_file"
                    notify-send -t 2500 "To-Do-list" "Prio-task \"${new:1}\" was added!"
                elif [[ $new == \?* ]]
                then
                    todolist+=("? ${new:1}")
                    saveListToFile "todolist" "$todo_file"
                    notify-send -t 2500 "To-Do-list" "Stalled task \"${new:1}\" was added!"
                else
                    todolist+=(" $new")
                    saveListToFile "todolist" "$todo_file"
                    notify-send -t 2500 "To-Do-list" "Task \"$new\" was added!"
                fi

                log "Added \"$new\"" >> $log_file
            #else
            #    draw "main" 1
            #    printf '\e[41m%s\e[0m' "$(calcSpaces " [ERROR] Task name can't be nothing!")"
            #    log "ERROR: Failed to add \"$new\"" >> $log_file
            #    sleep 1.2
            fi
        ;; 

        ## STALL
        q|Q)
            draw "main" 0
            if [[ "${todolist[$where]}" == \?* ]]; 
            then
                todolist[$where]="${todolist[$where]:1}"
                log "Unstalled \"${todolist[$where]}\"" >> $log_file
            else
                todolist[$where]="?${todolist[$where]}"
                log "Stalled \"${todolist[$where]}\"" >> $log_file
            fi
            ((where--))
            saveListToFile "todolist" "$todo_file"
        ;;   

        ### hide/show stalled
        h|H)
            if [[ $show_stalled -eq 1 ]]
            then
                show_stalled=0
                echo "0" > $show_stalled_file
                log "Hide stalled" >> $log_file
            else
                show_stalled=1
                echo "1" > $show_stalled_file
                log "Show stalled" >> $log_file
            fi
        ;;

        ## DUPLICATE
        v|V)
            todolist+=("${todolist[$where]}")
            log "Duplicated $todolist[$where]" >> $log_file
            saveListToFile "todolist" "$todo_file"
        ;;    
        
        ## REMOVE
        $'\177')
            currentmode=main
            draw "main" 1
            read -n 1 -s -p " > Are you sure you want to remove task $(($where+1))?" confirmremove

            if [[ $confirmremove == "" ]]
            then
                trashcan+=("${todolist[$where]}")
                log "Removed \"${todolist[$where]}\" and moved to trashcan" >> $log_file
                todolist=("${todolist[@]:0:$where}" "${todolist[@]:$(($where + 1))}") # overwrite array with elements before and after the element that is being removed, that way the indexes are correct again
                if [[ ! $where -eq 0 ]]
                then
                    ((where--))
                fi
            fi

            saveListToFile "todolist" "$todo_file"
            saveListToFile "trashcan" "$trashcan_file"
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
                    rm $todo_file
                    lof "Cleared list" >> $log_file
                    notify-send -t 2500 "To-Do-list" "List was cleared!"
                fi
            fi

            where=0
        ;;

        ## EXIT
        e|E|$'\e')
            log "TERMINATED" >> $log_file
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
                saveListToFile "todolist" "$todo_file"
            fi
        ;;

        ## MANUAL BACKUP
        b|B)
            read -n 1 -s -p " > Do you want to perfom a backup?: " confirm

            if [[ $confirm == "" ]]
            then
                saveListToFile "todolist" "$todo_backup_file"
                log "Manual backup performed" >> $log_file

            fi
        ;;

        ## RENAME <--- INCOMPLETE
        r|R)
            currentmode=main
            draw "main" 1
            tput cnorm
            #read -p " > Input new name for task $(($where+1)): " newname
            if [[ ${todolist[$where]} == !* ]]
            then
                newname=$(dialog --stdout --inputbox "New task:" 8 70 "${todolist[$where]:2}")
            else
                newname=$(dialog --stdout --inputbox "New task:" 8 70 "${todolist[$where]:1}")
            fi

            #if [[ $newname == "c" ]]
            #then
            #    :
            #elif [[ -z $newname ]]
            #then
            #    draw "main" 1
            #    printf '\e[41m%s\e[0m' "$(calcSpaces " [ERROR] Task name can't be nothing!")" 
            #    sleep 1.2
            #else
            #    if [[ "${todolist[$where]}" == !* ]]
            #    then
            #        todolist[$where]="! $newname"
            #    else
            #        todolist[$where]=" $newname"
            #    fi
            #fi

            if [[ -n $newname ]]
            then
                if [[ "${todolist[$where]}" == !* ]]
                then
                    todolist[$where]="! $newname"
                else
                    todolist[$where]=" $newname"
                fi
            fi

            saveListToFile "todolist" "$todo_file"
        ;;

        ## UNDO
        z|Z)
            :
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
                        saveListToFile "todolist" "$todo_file"
                        saveListToFile "trashcan" "$trashcan_file"
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
                        saveListToFile "trashcan" "$trashcan_file"
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
                                rm $trashcan_file
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

                                                            #if [[ ! visuals["Background Color"] == "#333333" ]]
                                                            #then
                                                            #    visuals["Background Color"] = "#3333332"
                                                            #    echo "bindsym \$mod+t exec kitty --title "To-Do" --class "todo" --override background=#333333 --override foreground=#ffffff -e ~/scripts/todolist/todolist_main.sh" > $backgroundcolor_sway
                                                            #    echo "#333333" > $background_colorcode
                                                            #    swaymsg reload
                                                            #    killall waybar && waybar &
                                                            #    exit
                                                            #fi
                                                        ;;
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
                                                "Background color")
                                                    echo
                                                    echo "${bold} This is an EXPERIMENTAL feature and could break stuff!${normal}"
                                                    echo
                                                    read -p " > Input colorcode (syntax: #ffffff): #" background_colorcode_temp
                                                    read -p " >> Are you sure you want to set #"$background_colorcode_temp" as your background colorcode? (Y/n) " confirm
                                                    visuals["Theme"]="Custom0"
                                                    echo "Custom" > $theme_file
                                                    if [[ $confirm == "Y" ]]
                                                    then
                                                        echo "bindsym \$mod+t exec kitty --title "To-Do" --class "todo" --override background=#"$background_colorcode_temp" --override foreground=#ffffff -e ~/scripts/todolist/todolist_main.sh" > $backgroundcolor_sway
                                                        echo "#"$background_colorcode_temp"" > $background_colorcode
                                                        swaymsg reload
                                                        killall waybar && waybar &
                                                        exit
                                                    fi
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
                            elif [[ ${optionsList[$optionswhere]} == "Windowoptions" ]]
                            then
                                winloop=1
                                while [[ $winloop -eq 1 ]];
                                do
                                    currentmode=window
                                    tput civis
                                    draw "window"

                                    option5=$(read_key)

                                    case $option5 in
                                        ## UP
                                        w|W|$'\e[A')
                                            draw "window"
                                            winwhere=$(move_up "window" "$winwhere")
                                        ;;

                                        ## DOWN
                                        s|S|$'\e[B')
                                            draw "window"
                                            winwhere=$(move_down "window" "$winwhere")
                                        ;;

                                        ## SELECT
                                        "")
                                            case "${windowOrder[$winwhere]}" in
                                                *Mode*)
                                                    :
                                                ;;

                                                *Size*)
                                                    echo
                                                    read -p " > Input Width: " windowWidth
                                                    read -p " > Input Height: " windowHeight
                                                    echo "$windowWidth"x"$windowHeight" > $window_size_SAFE
                                                    window["Size"]="$(cat $window_size_SAFE)1"
                                                    echo "for_window [app_id="todo"] floating enable, resize set $windowWidth $windowHeight, border pixel 4" > $window_size_sway
                                                    swaymsg reload
                                                    killall waybar && waybar &
                                                    exit
                                                ;;

                                                *Position*)
                                                    :
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
                                            winloop=0
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
            if [[ -f $todo_file ]]
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
                    saveListToFile "todolist" "$todo_file"
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
