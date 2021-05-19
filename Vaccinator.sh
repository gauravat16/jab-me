#!/bin/bash

setup_env() {
    if ! [ -x "$(command -v wget)" ]; then
        echo 'Error: wget is not installed. Install via a package manager.'
        exit
    fi

    if ! [ -x "$(command -v curl)" ]; then
        echo 'Error: curl is not installed. Install via a package manager.'
        exit
    fi

    if ! [ -x "$(command -v jq)" ]; then
        echo 'Error: jq is not installed. Install via a package manager.'
        exit
    fi

    unameOut="$(uname -s)"
    case "${unameOut}" in
    Linux*) machine=Linux ;;
    Darwin*) machine=Mac ;;
    CYGWIN*) machine=Cygwin ;;
    MINGW*) machine=MinGw ;;
    *) machine="UNKNOWN:${unameOut}" ;;
    esac
}
setup_vars() {
    local hash="$1"

    setup_env
    resources="$(pwd)/resources/$hash"
    bin="$(pwd)/bin"
    districts='districts.json'
    states='states.json'
    availability='availability.json'
    notif='DESKTOP'
    chat_id='-1001408368095'
    token="1725093954:AAF3AAa-2hiOoXX_Ur7gIcN1ZJip28BxqhA"
    make_dirs
}

make_dirs() {
    mkdir -p $bin
    mkdir -p $resources
}

post_notifications() {

    case "$notif" in
    "DESKTOP")

        case $machine in
        Linux)
            notify-send -i "$1"
            ;;

        Mac)
            command="display notification \"$1\" with title \"Jab Me\" "
            osascript -e "$command"
            ;;

        esac
        ;;

    "TELEGRAM")
        local resp=$(curl -sb --request POST "https://api.telegram.org/bot$token/sendMessage" \
            --header 'Content-Type: application/json' \
            --data-raw "{
                        \"chat_id\": $chat_id,
                        \"text\": \"$1\",
                        \"parse_mode\": \"Markdown\"
        }")

        # local msg_id="$(echo "$resp" | jq -r ".result|.message_id")"
        # delete_message "$(($msg_id+1))"
        ;;
    esac

}

delete_message() {
    local msg_id="$1"

    curl --location --request GET "https://api.telegram.org/bot$token/deleteMessage?chat_id=$chat_id&message_id=$msg_id"
}

menu_creator() {
    clear
    local json_file="$1"
    local jq_param="$2"
    local index=0
    local IFS=$'\n'
    for val in $(jq -r "$jq_param" "$json_file"); do
        echo "$index. $val"
        index=$((index + 1))
    done

    echo "Choose Option"
    read -r global_menu_option

    if ! [[ $global_menu_option =~ '^[0-9]+$' ]] && [[ -z "$global_menu_option" || $global_menu_option -ge $index ]]; then
        echo "Enter valid value"
        menu_creator $1 $2
    fi
}

download_states_response() {
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/admin/location/states" -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="90", "Google Chrome";v="90"' \
        -H 'accept: application/json' \
        -H 'dnt: 1' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36' \
        -H 'origin: https://apisetu.gov.in' \
        -H 'sec-fetch-site: cross-site' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-dest: empty' \
        -H 'referer: https://apisetu.gov.in/public/marketplace/api/cowin' \
        -H 'accept-language: en-IN,en;q=0.9,en-GB;q=0.8,en-US;q=0.7,hi;q=0.6')" >$resources/$states
}

download_availability_by_district_response() {
    local district="$1"
    local date="$2"
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByDistrict?district_id=$district&date=$date" -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="90", "Google Chrome";v="90"' \
        -H 'accept: application/json' \
        -H 'dnt: 1' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36' \
        -H 'origin: https://apisetu.gov.in' \
        -H 'sec-fetch-site: cross-site' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-dest: empty' \
        -H 'referer: https://apisetu.gov.in/public/marketplace/api/cowin' \
        -H 'accept-language: en-IN,en;q=0.9,en-GB;q=0.8,en-US;q=0.7,hi;q=0.6')" >$resources/$availability
}

download_availability_by_pincode_response() {
    local pincode="$1"
    local date="$2"
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/appointment/sessions/public/calendarByPin?pincode=$pincode&date=$date" -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="90", "Google Chrome";v="90"' \
        -H 'accept: application/json' \
        -H 'dnt: 1' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36' \
        -H 'origin: https://apisetu.gov.in' \
        -H 'sec-fetch-site: cross-site' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-dest: empty' \
        -H 'referer: https://apisetu.gov.in/public/marketplace/api/cowin' \
        -H 'accept-language: en-IN,en;q=0.9,en-GB;q=0.8,en-US;q=0.7,hi;q=0.6')" >$resources/$availability
}

download_district_response() {
    local state="$1"
    echo "$(curl -s -G "https://cdn-api.co-vin.in/api/v2/admin/location/districts/$state" -H 'sec-ch-ua: " Not A;Brand";v="99", "Chromium";v="90", "Google Chrome";v="90"' \
        -H 'accept: application/json' \
        -H 'dnt: 1' \
        -H 'sec-ch-ua-mobile: ?0' \
        -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36' \
        -H 'origin: https://apisetu.gov.in' \
        -H 'sec-fetch-site: cross-site' \
        -H 'sec-fetch-mode: cors' \
        -H 'sec-fetch-dest: empty' \
        -H 'referer: https://apisetu.gov.in/public/marketplace/api/cowin' \
        -H 'accept-language: en-IN,en;q=0.9,en-GB;q=0.8,en-US;q=0.7,hi;q=0.6')" >$resources/$districts
}

handle_availability() {
    local count=$(jq -r ".centers| .[] | .sessions | .[] | select(.available_capacity > 0 )| select(.min_age_limit >= $min_age) | select(.min_age_limit <= $max_age)" $resources/$availability | wc -l)
    if ! [[ -z "$count" ]] && [[ $count -gt 0 ]]; then
        post_notifications "$(echo "$(prepare_message)" | cut -c 1-1000)...."
    else
        echo "No Vaccination Centre found!"
    fi
}

prepare_message() {
    local IFS=$'\n'
    local state="$(jq -r ".centers| .[0] | .state_name" $resources/$availability)"
    local district="$(jq -r ".centers| .[0] | .district_name" $resources/$availability)"
    local message="$(hostname) says: *State: #${state// /_}* & *District : #${district// /_}* & *Age Group: ($min_age+)*\n"
    message=$message"Following centres are available :\n\n"
    for centre in $(jq -r ".centers| .[] | select(.sessions[].available_capacity > 0 )|select(.sessions[].min_age_limit >= $min_age) | select(.sessions[].min_age_limit <= $max_age) | \"Centre Name : \(.name) [State : \(.state_name) District : \(.district_name)] \" " $resources/$availability | uniq); do
        message=$message" $centre\n"
    done

    echo "$message"
}

ask_for_age() {
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
        max_age=99
        min_age=45
        ;;
    *)
        echo "Enter valid value"
        ask_for_age
        ;;
    esac
}

ask_for_location() {
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
        ;;
    esac
}

find_vaccination_centre_by_location() {
    download_states_response
    menu_creator "$resources/$states" ".states | .[] | .state_name"

    local state_id="$(jq -r ".states | .[$global_menu_option] | .state_id" "$resources/$states")"
    download_district_response "$state_id"
    menu_creator "$resources/$districts" '.districts | .[] | .district_name'

    local district_id="$(jq -r ".districts | .[$global_menu_option] | .district_id" "$resources/$districts")"
    download_availability_by_district_response "$district_id" "$(date +"%d-%m-%Y")"
    handle_availability
}

find_vaccination_centre_by_pincode() {
    if [[ -z $1 ]]; then
        clear
        echo "Enter pincode"
        read -r pincode
    else
        pincode="$1"
    fi

    if [[ -z "$pincode" ]] && ! [[ $pincode =~ '^[0-9]+$' ]]; then
        echo "Enter valid pincode!"
        find_vaccination_centre_by_pincode
    fi

    download_availability_by_pincode_response "$pincode" "$(date +"%d-%m-%Y")"
    handle_availability
}

init() {

    hash=$(echo "$@" | shasum)
    setup_vars $hash

    local usage="Usage
--m: mode,
--pincode: pincode for the centre,
--district: district code (To get this number please run the script in manual mode and check resources/district.json
--age-max: Max age for vaccination
--h: help
--notif: Notification Options: Desktop notifications (DESKTOP) (Deafult) or Telegram (TELEGRAM) "
    local location_mode=
    local pincode=
    local district_id=
    local mode=
    min_age=18

    if [ "$#" -eq 0 ]; then
        printf "$usage"
    fi

    for option; do
        case "$prev_option" in
        '--m')
            mode=$option
            ;;
        '--pincode')
            location_mode='P'
            pincode=$option
            ;;

        '--district')
            location_mode='D'
            district_id=$option
            ;;

        '--age-max')
            max_age=$option
            ;;

        '--notif')
            notif=$option
            ;;

        "") ;;

        \
            '--h')
            echo $usage
            ;;
        esac

        prev_option="$option"

    done

    if [[ "$max_age" -le 44 ]];
        then
            min_age=18
    fi

    if [[ "$max_age" -gt 44 ]];
        then
            min_age=45
    fi

    case $mode in
    'A')
        echo "Script in AutoMode!"
        case $location_mode in
        'P')
            for element in ${pincode//,/ }; do
                find_vaccination_centre_by_pincode "$element"
            done
            ;;
        'D')
            for element in ${district_id//,/ }; do
                download_availability_by_district_response "$element" "$(date +"%d-%m-%Y")"
                handle_availability
            done
            ;;
        *) ;;

        esac
        ;;

    'M')
         
        ask_for_age
        ask_for_location
        ;;

    *)
        echo "Usage M: Manual input, A: Automatic"
        ;;
    esac
}

init "$@"
