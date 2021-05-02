#!/bin/bash

setup_env(){
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     machine=Linux;;
        Darwin*)    machine=Mac;;
        CYGWIN*)    machine=Cygwin;;
        MINGW*)     machine=MinGw;;
        *)          machine="UNKNOWN:${unameOut}"
    esac
}
setup_vars(){
    setup_env
    resources="resources"
    bin="bin"
    districts='districts.json'
    states='states.json'
    availability='availability.json'
    make_dirs
    get_jq
    jq="$bin/jq"
    ask_for_age
}

make_dirs(){
    mkdir -p $(pwd)/$bin
    mkdir -p $(pwd)/$resources
}

get_jq(){
    curr_path="$(pwd)"
    cd $bin
    if [[ ! -f jq ]]
    then
        case $machine in
            Linux)
                wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
                mv jq-linux64 jq
            ;;
            
            Mac)
                wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-osx-amd64
                mv jq-osx-amd64 jq
                
            ;;
            
        esac
        
        chmod u+x jq
    fi
    
    cd $curr_path
}


post_notifications(){
    
    case $machine in
        Linux)
            notify-send -i "$1"
        ;;
        
        Mac)
            command="display notification \"$1\" with title \"Jab Me\" "
            osascript -e "$command"  
        ;;
        
    esac
}


menu_creator(){
    clear
    local json_file="$1"
    local jq_param="$2"
    local index=0
    local IFS=$'\n' 
    for val in $($jq -r "$jq_param" "$json_file" ); do
        echo "$index. $val"  
        index=$((index+1))
    done
    
    echo "Choose Option"
    read -r global_menu_option

    if ! [[ $global_menu_option =~ '^[0-9]+$' ]] && [[ -z "$global_menu_option" || $global_menu_option -ge $index ]];
    then
        echo "Enter valid value"
        menu_creator $1 $2       
    fi
}


download_states_response(){
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/admin/location/states")" > $resources/$states
}

download_availability_by_district_response(){
    local district="$1"
    local date="$2"
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$district&date=$date")" > $resources/$availability
}

download_availability_by_pincode_response(){
    local pincode="$1"
    local date="$2"
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByPin?pincode=$pincode&date=$date")" > $resources/$availability
}

download_district_response(){
    local state="$1"
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/admin/location/districts/$state")" > $resources/$districts
}

handle_availability(){
    local count=$($jq -r ".centers| .[] | .sessions | .[] | select(.available_capacity > 0 )| select(.min_age_limit >= $min_age) | select(.min_age_limit <= $max_age)" $resources/$availability | wc -l)
    if ! [[ -z "$count" ]]  && [[ $count -gt 0 ]];
    then
        post_notifications "$(prepare_message)"
    else
        post_notifications "No Vaccination Centre found!"
    fi
}

prepare_message(){
    local IFS=$'\n' 
    local message="Following centres are available :\n"
    for centre in $($jq -r ".centers| .[] | select(.sessions[].available_capacity > 0 )|select(.sessions[].min_age_limit >= $min_age) | select(.sessions[].min_age_limit <= $max_age) | \"Centre Name : \(.name)\" " $resources/$availability | uniq );do
        message=$message" $centre\n"
    done

    echo "$message"
}

ask_for_age(){
    clear
    echo "Choose Age group"
    echo "1. 18-44"
    echo "2. 45+"

    read -r option
    
    case $option in
      1)
        max_age=44
        min_age=18
        ;;
      2)
        max_age=9999
        min_age=45
        ;;
      *)
        echo "Enter valid value"
        ask_for_age
    esac
}

ask_for_location(){
    clear
    echo "Search for vaccination centre via:"
    echo "1. Pincode"
    echo "2. State and District"

    read -r option
    
    case $option in
      1)
        find_vaccination_centre_by_pincode
        ;;
      2)
        find_vaccination_centre_by_location
        ;;
      *)
        echo "Enter valid value"
        ask_for_age
    esac
}

find_vaccination_centre_by_location(){
    download_states_response
    menu_creator "$resources/$states" ".states | .[] | .state_name"

    local state_id="$($jq -r ".states | .[$global_menu_option] | .state_id" "$resources/$states")"
    download_district_response "$state_id"
    menu_creator "$resources/$districts" '.districts | .[] | .district_name'

    local district_id="$($jq -r ".districts | .[$global_menu_option] | .district_id" "$resources/$districts")"
    download_availability_by_district_response "$district_id"  "$(date +"%d-%m-%Y")"
    handle_availability
}

find_vaccination_centre_by_pincode(){
    clear
    echo "Enter pincode"
    read -r pincode
    
    if [[ -z "$pincode" ]] && ! [[ $pincode =~ '^[0-9]+$' ]];
    then
        echo "Enter valid pincode!"
        find_vaccination_centre_by_pincode       
    fi

    download_availability_by_pincode_response "$pincode" "$(date +"%d-%m-%Y")"
    handle_availability
}


init(){
    setup_vars
    ask_for_location   
}

init
