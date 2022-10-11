#!/bin/sh

config="$HOME/.config/monitors.json"
lock_dir="/tmp/setmonitors.lock"
loop=true

# process parameters
while test $# -gt 0
do
    case "$1" in
        -c|--config)
            config=$2
            shift 2
        ;;
        -k|--kill)
            if ! kill -9 $(cat "$lock_dir/pid" 2> /dev/null) > /dev/null 2>&1
            then
                echo "Script is not running; cannot be killed"
            fi
            exit
        ;;
        -o|--one-shot)
            loop=false
            shift
        ;;
        *)
            echo "Unexpected: $1"
            exit 1
        ;;
    esac
done

# find the config file
if [[ ! -f $config ]]
then
    echo "Config file not found: $config"
    exit 1
elif ! cat $config | jq > /dev/null
then
    echo "Config file has bad json format"
    exit 1
fi
config=$(cat $config | jq -c)

# ensure only one instance is running
if ! mkdir $lock_dir > /dev/null 2>&1 && ps -p $(cat "$lock_dir/pid") > /dev/null 2>&1
then
    echo "Script is already running"
    if [[ $loop == "false" ]]
    then
        echo "If using --one-shot, please kill the running script first"
    fi
    exit 1
fi
echo $$ > "$lock_dir/pid"
rm -rf $lock_dir/setting

function set_all_monitors {
    IFS=$'\n'
    
    while ! mkdir "$lock_dir/setting" > /dev/null 2>&1
    do
        echo "Monitors already being set"
        sleep 1
    done
    
    declare -A monitor_names monitors monitor_layouts monitor_widths monitor_heights
    
    # get all connected monitors
    for monitor_info in $(xrandr --verbose | sed 's/\t/ /g' | tr -s ' ' | sed -z 's/\n //g' | grep -P '^[a-zA-Z0-9\-]+ (dis)?connected ')
    do
        monitor=$(echo $monitor_info | cut -d " " -f 1)
        if [[ $(echo $monitor_info | cut -d " " -f 2) == connected ]]
        then
            monitors[$monitor]=connect
            edid=$(echo $monitor_info | grep -oP 'EDID\: [a-f0-9]{20}' | cut -d " " -f 2)
            monitor_name=$(echo $config | jq -r '.monitors[] | select(.edid == "'$edid'") | .monitor')
            if [[ ! -z $monitor ]] && [[ ! -z $monitor_name ]]
            then
                monitor_names[$monitor_name]=$monitor
            fi
            monitor_widths[$monitor]=$(echo $monitor_info | grep -oP '\+preferred.*?width [0-9]+' | rev | cut -d " " -f 1 | rev)
            monitor_heights[$monitor]=$(echo $monitor_info | grep -oP '\+preferred.*?height [0-9]+' | rev | cut -d " " -f 1 | rev)
        else
            monitors[$monitor]=disconnect
        fi
    done
    
    # find the layout based on connected monitors
    for potential_layout in $(echo $config | jq -c '.layouts[] | select(.skip != true)')
    do
        for monitor_info in $(echo $potential_layout | jq -c '.monitors[]?')
        do
            monitor=$(echo $monitor_info | jq -r '.monitor')
            [[ $(echo $monitor_info | jq -r '.connected') != false ]] && wants_connected=true || wants_connected=false
            [[ -n ${monitor_names[$(echo $monitor_info | jq -r '.monitor')]+is_set} ]] && is_connected=true || is_connected=false
            if [[ $wants_connected == $is_connected ]]
            then
                layout=$potential_layout
            else
                layout=
                break
            fi
        done
        if [[ ! -z $layout ]]
        then
            break
        fi
    done
    if [[ -z $layout ]]
    then
        echo "Could not determine layout"
        rmdir "$lock_dir/setting"
        return 1
    fi
    
    # find and set the primary monitor
    primary=${monitor_names[$(echo $layout | jq -r '.primary.monitor')]}
    if [[ -z $primary ]] || [[ ${monitors[$primary]} != "connect" ]]
    then
        echo "Bad primary monitor chosen"
        rmdir "$lock_dir/setting"
        return 1
    fi
    monitor_layouts[$primary]=$(echo $layout | jq -c '.primary')
    
    # get default monitor layout
    default_monitor_layout=$(echo $layout | jq -c '.default')
    if [[ $default_monitor_layout == "null" ]]
    then
        default_monitor_layout=
    fi
    
    pkill polybar
    
    # prepare xrandr args
    xrandr_args=( --output $primary --primary --panning 0x0 )
    screen_north=0
    screen_east=0
    screen_south=0
    screen_west=0
    
    # function for setting up monitor positioning ($1=monitor)
    function set_monitor() {
        if [[ ! -n ${monitors[$1]+is_set} ]]
        then
            echo "Invalid monitor provided: $1"
            return 1
        fi
        monitor=$1
        
        function disconnect_monitor() {
            # add xrandr arguments
            xrandr_args+=( --output $monitor --off )
            monitors[$monitor]="disconnected"
        }
        
        function connect_monitor() {
            xrandr_args+=( --output $monitor )
            
            # get position scheme
            position=$(echo ${monitor_layouts[$monitor]} | jq -r .position)
            if [[ -z $position ]] || [[ $position == "null" ]]
            then
                position=$(echo $default_monitor_layout | jq -r .position)
                if [[ -z $position ]] || [[ $position == "null" ]]
                then
                    echo "Warning: no default position for monitor $monitor, disconnecting"
                    disconnect_monitor
                    return
                fi
            fi
            # get monitor width and height
            width=$(echo ${monitor_layouts[$monitor]} | jq -r .width)
            if [[ -z $width ]] || [[ $width == "null" ]]
            then
                width=${monitor_widths[$monitor]}
            fi
            height=$(echo ${monitor_layouts[$monitor]} | jq -r .height)
            if [[ -z $height || $height == "null" ]]
            then
                height=${monitor_heights[$monitor]}
            fi
            if [[ -z $width ]] || [[ -z $height ]]
            then
                echo "Invalid width or height for monitor $monitor, disconnecting"
                disconnect_monitor
                return
            fi
            # format and calculate positions
            position=${position//north/$screen_north}
            position=${position//east/$screen_east}
            position=${position//south/$screen_south}
            position=${position//west/$screen_west}
            position=${position//width/$width}
            position=${position//height/$height}
            position_x=$(echo $position | cut -d 'x' -f 1 | bc | cut -d "." -f 1)
            position_y=$(echo $position | cut -d 'x' -f 2 | bc | cut -d "." -f 1)
            # update new screen bounding rectangle
            (( $position_x < $screen_west )) && screen_west=$position_x
            (( $position_y < $screen_north )) && screen_north=$position_y
            (( $position_x+$width > $screen_east )) && screen_east=$(( $position_x+$width ))
            (( $position_y+$height > $screen_south )) && screen_south=$(( $position_y+$height ))
            # add xrandr arguments
            xrandr_args+=( --mode "${width}x${height}" --pos "${position_x}x${position_y}" )
            
            # set refresh rate
            rate=$(echo ${monitor_layouts[$monitor]} | jq -r .rate)
            if ! [[ -z $rate || $rate == "null" ]]
            then
                xrandr_args+=( --rate "${rate}" )
            fi
            
            monitors[$monitor]="connected"
        }
        
        case ${monitors[$monitor]} in
            connect)
                connect_monitor
            ;;
            disconnect)
                disconnect_monitor
            ;;
            *ed)
                echo "Warning: monitor $monitor is already setup"
            ;;
        esac
    }
    
    # start with the primary monitor
    set_monitor $primary
    
    # find defined monitor layouts
    for monitor_layout in $(echo $layout | jq -c '.auxiliary[]?')
    do
        monitor=${monitor_names[$(echo $monitor_layout | jq -r '.monitor')]}
        if [[ -z $monitor ]]
        then
            echo "Unknown monitor in layout: $(echo $monitor_layout | jq -r '.monitor')"
            continue
        fi
        if [[ -z ${monitor_layouts[$monitor]} ]]
        then
            monitor_layouts[$monitor]=$monitor_layout
            set_monitor $monitor
        fi
    done
    
    # setup remaining monitors
    for monitor in ${!monitors[@]}
    do
        if [[ ${monitors[$monitor]} != *"ed" ]]
        then
            set_monitor $monitor
        fi
    done
    
    # run the setup
    xrandr "${xrandr_args[@]}"
    
    # set up pre-existing bspwm desktops
    for monitor in $(bspc query -M --names)
    do
        for desktop in {1..10}
        do
            bspc query -N -d $monitor:^$desktop | while read node_id
            do
                bspc node $node_id -d $primary:^$desktop
            done
        done
        if [[ -z ${monitors[$monitor]} ]] || [[ ${monitors[$monitor]} == "disconnected" ]]
        then
            bspc monitor $monitor -r
        fi
    done
    
    # set up connected desktops
    for monitor in ${!monitors[@]}
    do
        if [[ ${monitors[$monitor]} == "connected" ]]
        then
            # set bspwm desktops
            bspc monitor $monitor -d 1 2 3 4 5 6 7 8 9 10
            
            # set polybar
            polybar_bar=$(echo ${monitor_layouts[$monitor]} | jq -r .polybar)
            if [[ -z $polybar_bar || $polybar_bar == "null" ]]
            then
                polybar_bar=$(echo $default_monitor_layout | jq -r .polybar)
            fi
            if ! [[ -z $polybar_bar && $polybar_bar == "null" && $polybar_bar == "none" ]]
            then
                (sleep 4; MONITOR=$monitor polybar $polybar_bar) &
            fi
            
            # set touchscreen
            touchscreen=$(echo ${monitor_layouts[$monitor]} | jq -r .touchscreen)
            if ! [[ -z $touchscreen || $touchscreen == "null" ]]
            then
                xinput --map-to-output "${touchscreen}" "${monitor}"
            fi
        fi
    done
    
    $HOME/bin/setwallpaper.sh
    
    rmdir "$lock_dir/setting"
}

if [[ $loop == "true" ]]
then
    echo looping
else
    set_all_monitors
fi

rm -rf $lock_dir

#udevadm monitor --udev | while read line
#do
#if [[ "$line" = *" change "* ]] && [[ "$line" = *" (drm)" ]]
#then
#set_all_monitors
#fi
#done &

#monitor-sensor | while read line
#do
#if [[ ${line,,} = *"accelerometer"* ]] && [[ ${line,,} = *"orientation"* ]]
#then
#orientation=$(echo $line | cut -d ":" -f 2 | cut -d " " -f 2 | cut -d ")" -f 1)

#case $orientation in
#"normal") rotation="normal" ;;
#"bottom-up") rotation="inverted" ;;
##"left-up") rotation="left" ;;
##"right-up") rotation="right" ;;
#*) continue ;;
#esac

#xrandr --output "$monitor_to_rotate" --rotate "$rotation"
#xinput --map-to-output  "$touchscreen_to_rotate" "$monitor_to_rotate"
#fi
#done &
