
### Purpose
The purpose of setting up a provisioning computer (laptop) is to have a system that will:

- Install apps
- Rename the device (Bluetooth name)
- Connect it to the provisioning WiFi network
- Disable unwanted apps
- Silence device
- Adjust brightness
- etc.

### Setup
The procedure is very simple. The selected computer should have linux installed on it.
Then carefully follow these steps to get the computer all set up for the task.

**1**. Make sure the computer is connected to the Internet

**2**. In a terminal, execute the following commands

    sudo apt update
    sudo apt install -y git adb jq

**3**. Change directory in to Desktop then execute the following command

    git clone --branch mauritius https://github.com/tech-acs/adb_bash.git

**4**. Make sure the apps (apks) you want to be installed have been added to the apk directory

**5**. Carefully edit the included init.json file and put in the correct SSID and password of your
WiFi network.

Once you successfully complete the above steps, the computer shall be ready to provision tablets
and carry out all related activities as stated above. You should also have a barcode reader plugged in to the computer to start assigning tablets. While this is not necessary, it will greatly speed up the process if available. If not, you can manually type in the tablet name/code.

### Use

Run the script and follow the prompts

    ./mauritius.sh
