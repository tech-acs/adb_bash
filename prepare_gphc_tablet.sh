#!/bin/bash

uninstall_old_apps () {
    echo "Uninstalling old provisioner and QA check..."
    adb shell pm uninstall -k --user 0 com.provisioner
    adb shell pm uninstall -k --user 0 com.qacheck
    echo "Done!"
}

install_apks () {
    for file in 'apks'/*; do
        echo "Installing $file..."
        adb install -g "$file"
        echo "Done!"
    done
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
    echo "Assigning device name..."
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
    adb shell am start -n com.steinwurf.adbjoinwifi/.MainActivity -e ssid $ssid -e password_type WPA -e password $password
}

extract_district_code () {
    district_code=${1:0:7}
}

grant_permissions() {
    adb shell pm grant com.sophos.mobilecontrol.client.android android.permission.READ_PHONE_STATE
}

disable_developer_options() {
    adb shell settings put global development_settings_enabled 0
}

while true; do
    # uninstall_old_apps
    read -p "Scan geocode: " code
    extract_district_code $code
    assign_geocode $district_code
    install_apks
    # grant_permissions
    change_device_name $code
    copy_file "./init.json" "/sdcard/Download/"
    connect_wifi
    echo -e "\n=======================================================\n"
done
