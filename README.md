
### Purpose
The purpose of setting up a provisioning computer (laptop) is to have a system that will:

- Assign the districts to tablets
- Delete and uninstall the old version of csentry
- Install the provisioning and other apps
- Rename the device (Bluetooth name)
- Connect it to the provisioning WiFi network
- Copy the init.json file that has the address of the provisioning web server (which will be
needed by the provisioning app in the next stage)

### Setup
The procedure is very simple. The selected computer should have linux installed on it.
Then carefully follow these steps to get the computer all set up for the task.

**1**. Make sure the computer is connected to the Internet

**2**. In a terminal, execute the following commands

    sudo apt update
    sudo apt install -y git adb jq

**3**. Change directory in to Desktop then execute the following command

    git clone --branch gphc https://github.com/amestsantim/adb_bash.git

**4**. Make sure the apps (apks) you want to be installed have been added to the apk directory

**5**. Carefully edit the included init.json file and put in the correct SSID and password of your
WiFi network. Also, edit the loopup_url to reflect the correct IP address of the provisioning web
server.

Once you successfully complete the above steps, the computer shall be ready to assign tablets
and carry out all related activities as stated above. You will also be
needing a barcode reader plugged in to start assigning tablets.

### Use

Run the script and follow the prompts

    ./assign_gphc_tablets.sh
