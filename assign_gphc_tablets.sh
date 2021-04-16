#!/bin/bash

ALLOWED_TIME_DRIFT_IN_SECONDS=600
DELAY=2

start_intent() {
    adb shell am start -a $1
    sleep $DELAY
}

tap() {
    adb shell input tap $1 $2
    sleep $DELAY
}

type_text() {
    adb shell input keyboard text $1
    # Press enter (ok button)
    #adb shell input keyevent KEYCODE_ENTER
    sleep $DELAY
}

go_home() {
    adb shell input keyevent KEYCODE_HOME
}

clear_textbox() {
    adb shell input keyevent KEYCODE_MOVE_END
    adb shell input keyevent --longpress $(printf 'KEYCODE_DEL %.0s' {1..50})
}

press_power_button() {
    adb shell input keyevent KEYCODE_POWER
    sleep $DELAY
}

swipe_up() {
    adb shell input touchscreen swipe 300 400 300 0
}

screen_is_on() {
    screen_is_on="$(adb shell dumpsys input_method | grep -c "mInteractive=true")"
}

turn_screen_on() {
    press_power_button
    swipe_up
}

disable_screen_rotation() {
    adb shell content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
}

set_huawei_device_bluetooth_name() {
    # Subshell runs similar to try/catch
    (
        # The -e flag will make the subshell exit immedietely on the first error
        set -e

        echo -e "Setting device bluetooth name..."
        
        #check_screen_status
        
        if ! screen_is_on ; then
            turn_screen_on
        fi

        disable_screen_rotation

        go_home
        start_intent "android.bluetooth.adapter.action.REQUEST_ENABLE"
        # Press the 'ALLOW' button
        tap 530 690

        # Open bluetooth settings screen
        start_intent "android.settings.BLUETOOTH_SETTINGS"
        
        # Tap on the 'Device name' line
        tap 600 300
        
        clear_textbox

        type_text $1

        # Tap on the 'SAVE' button
        tap 600 600
        
        go_home
    )

    if [ $? -ne 0 ]; then
        echo -e "FAILED!"
    else
        echo -e "Done!"
    fi
    #exit $?
}

# =================== All the above functions are here just to change huawei device BT name =========================

install_apks () {
    for file in 'apks'/*; do
        echo "Installing $file..."
        adb install -g "$file"
        echo "Done!"
    done
}

grant_permissions() {
    adb shell pm grant com.provisioner android.permission.WRITE_EXTERNAL_STORAGE
    adb shell pm grant com.provisioner android.permission.ACCESS_FINE_LOCATION
}

uninstall_app () {
    echo "Uninstalling app ($1)..."
    adb shell pm uninstall -k $1 2> /dev/null
    echo "Done!"
}

delete_folder () {
    echo "Deleting folder ($1)..."
    adb shell rm -r $1 2> /dev/null
    echo "Done!"
}

assign_geocode () {
    echo $1 > assigned_code
    echo "Assigning geocode $1 to tablet..."
    adb shell mkdir /sdcard/census_device_identity
    adb push ./assigned_code /sdcard/census_device_identity/
    echo "Done!"
}

stash_serial_on_tablet () {
    serial_no=$(adb get-serialno)
    echo $serial_no > serial
    echo "Pushing serial to tablet..."
    adb push ./serial /sdcard/census_device_identity/
    echo "Done!"
}

get_device_manufacturer () {
    manufacturer=$(adb shell getprop ro.product.manufacturer)
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
    adb shell settings put global adb_enabled 0
    adb shell pm clear com.android.settings
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
        adb shell am start -a android.settings.DATE_SETTINGS
        read -p "Please correct and press enter to try again "
        continue
    fi

    read -p "Scan barcode: " code
    uninstall_app "gov.census.cspro.csentry"
    delete_folder "sdcard/csentry"
    delete_folder "sdcard/Android/data/gov.census.cspro.csentry/files/csentry/Ghana-PHC-2021"
    extract_district_code $code
    assign_geocode $district_code
    stash_serial_on_tablet
    install_apks
    grant_permissions
    get_device_manufacturer
    if [ "$manufacturer" == "HUAWEI" ]; then
        set_huawei_device_bluetooth_name $code
    else
        change_device_name $code
    fi
    copy_file "./init.json" "/sdcard/Download/"
    connect_wifi
    disable_developer_options
    echo -e "\n============================ SUCCESSFULLY COMPLETED ===========================\n"

    read -p "Plug-in the next tablet and press enter when ready "
done
