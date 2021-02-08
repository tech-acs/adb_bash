#!/bin/bash

ALLOWED_TIME_DRIFT_IN_SECONDS=600

install_apks () {
    for file in 'apks'/*; do
        echo "Installing $file..."
        adb install -g "$file"
        echo "Done!"
    done
}

uninstall_app () {
    echo "Uninstalling app ($1)..."
    adb shell pm uninstall -k $1
    echo "Done!"
}

delete_folder () {
    echo "Deleting folder ($1)..."
    adb shell rm -r $1
    echo "Done!"
}

assign_geocode () {
    echo $1 > assigned_code
    echo "Assigning geocode $1 to tablet..."
    adb shell mkdir /sdcard/census_device_identity
    adb push ./assigned_code /sdcard/census_device_identity/
    echo "Done!"
}

copy_file () {
    echo "Copying $1 to $2 on tablet"
    adb push $1 $2
    echo "Done!"
}

change_device_name () {
    echo "Assigning device name ($1)..."
    adb shell settings put global device_name $1
    echo "Done!"
}

read_wifi_info () {
    wifi=$(jq .wifi init.json)
    ssid=$(echo $wifi | jq .ssid)
    password=$(echo $wifi | jq .password)
}

connect_wifi () {
    read_wifi_info
    echo "Attempting to connect to wifi ($ssid)..."
    adb shell am start -n com.steinwurf.adbjoinwifi/.MainActivity -e ssid $ssid -e password_type WPA -e password $password
    echo "Done!"
}

extract_district_code () {
    district_code=${1:0:7}
}

disable_developer_options() {
    adb shell settings put global development_settings_enabled 0
}

check_device_is_connected() {
    connected_devices=`adb devices | grep -v devices | grep device | cut -f 1`

    if [ `echo "$connected_devices" | wc -w` -gt 0 ]; then
        no_of_devices=`echo "$connected_devices" | wc -l`
    else
        no_of_devices=0
    fi
}

check_correct_device_time() {
    system_timestamp=$(date "+%s")
    device_timestamp=$(adb shell date "+%s")
    if (( system_timestamp >= device_timestamp )); then
        diff=$((system_timestamp-device_timestamp))
    else
        diff=$((device_timestamp-system_timestamp))
    fi

    if (( diff > ALLOWED_TIME_DRIFT_IN_SECONDS )); then
        device_time_correct=0
    else
        device_time_correct=1
    fi
}

while true; do
    check_device_is_connected
    if [ "$no_of_devices" != 1 ]; then
        echo -e "\nNo (or more than one) connected device detected"
        read -p "Make sure usb debugging is enabled and allowed from this computer then press enter to try again "
        continue
    fi

    check_correct_device_time
    if [ "$device_time_correct" == 0 ]; then
        echo -e "\nDevice has wrong date/time set."
        read -p "Please correct and press enter to try again "
        continue
    fi

    read -p "Scan barcode: " code
    uninstall_app "gov.census.cspro.csentry"
    delete_folder "sdcard/csentry"
    extract_district_code $code
    assign_geocode $district_code
    install_apks
    change_device_name $code
    copy_file "./init.json" "/sdcard/Download/"
    connect_wifi
    echo -e "\n============================ SUCCESSFULLY COMPLETED ===========================\n"
done
