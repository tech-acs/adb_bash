#!/bin/bash

uninstall_system_apps () {
    echo "Uninstalling system apps..."
    adb shell pm uninstall -k --user 0 com.abc
    adb shell pm uninstall -k --user 0 com.xyz
    echo "Done!"
}

install_apks () {
    for file in 'Apps'/*; do
        echo "Installing $file..."
        adb install -g "$file"
        echo "Done!"
    done
}

copy_files () {
    echo "Copy files to tablet..."
    adb push ./payload /sdcard/destination_path/
    echo "Done!"
}

change_device_name () {
    echo "Assigning device name..."
    adb shell settings put global device_name $1
    echo "Done!"
}

grant_permissions() {
    adb shell pm grant com.pqr android.permission.CAMERA
    adb shell pm grant com.def android.permission.ACCESS_FINE_LOCATION
}

disable_developer_options() {
    adb shell settings put global development_settings_enabled 0
}

while true; do
    read -p "Enter new device name: " code
    uninstall_system_apps
    install
    copy_files
    change_device_name $code
    grant_permissions
    disable_developer_options
    echo -e "\n=======================================================\n"
done