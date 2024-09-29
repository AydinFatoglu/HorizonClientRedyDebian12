#!/bin/bash

#repoları düzenle
# sources.list dosyasını yedekle
cp /etc/apt/sources.list /etc/apt/sources.list.backup

# sources.list dosyasındaki deb cdrom satırlarını yoruma al
sed -i '/^deb cdrom:/s/^/#/' /etc/apt/sources.list

# Online repository'lerin olup olmadığını kontrol et ve gerekirse ekle
if ! grep -q "deb http://deb.debian.org/debian/ bookworm" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free" >> /etc/apt/sources.list
    echo "deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free" >> /etc/apt/sources.list
    echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list
fi

# Paket listesini güncelle
apt update -y



#Gui Openbox
apt-get update -y 
apt-get upgrade -y
apt-get install lightdm openbox -y

#Client İnstall and prepaire
wget https://download3.omnissa.com/software/CART23FQ3_LIN64_2209/VMware-Horizon-Client-2209-8.7.0-20616018.x64.bundle
chmod +x VMware-Horizon-Client-2209-8.7.0-20616018.x64.bundle
yes yes | ./VMware-Horizon-Client-2209-8.7.0-20616018.x64.bundle --eulas-agreed --console --required \
--set-setting vmware-horizon usb true \
--set-setting vmware-horizon media true \
--set-setting vmware-horizon smartcard true \
--set-setting vmware-horizon rtav true \
--set-setting vmware-horizon tsdr true \
--set-setting vmware-horizon serialport true \
--set-setting vmware-horizon scanner true

apt install gcc-12 g++-12 -y
apt install python3-tk -y


# Define the username for auto-login
USERNAME="examuser"

# Function to check if the user exists
user_exists() {
    id "$USERNAME" &>/dev/null
}

# Function to create the user if it doesn't exist
create_user() {
    useradd -m -s /bin/bash "$USERNAME"
    echo "User '$USERNAME' created."
}

# Check if the user exists, if not, create the user
if user_exists; then
    echo "User '$USERNAME' already exists."
else
    echo "User '$USERNAME' does not exist. Creating user..."
    create_user
fi

# Backup the existing lightdm.conf file
cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.bak

# Modify the lightdm.conf file to enable auto-login
sed -i '/^\[Seat:\*\]/a autologin-user='$USERNAME'\nautologin-user-timeout=0' /etc/lightdm/lightdm.conf

# Set temporary example values
server="example-server.fqdn"
ebiuser="exampleuser"
ebipass="examplepassword"
domain="example.doin.netbios"
app="exampleapp"

# Create the Openbox configuration in the specific user's home directory
mkdir -p /home/$USERNAME/.config/openbox

# Create the autostart file in the user's home directory
cat << EOF > /home/$USERNAME/.config/openbox/autostart
# Loop to keep vmware-view running minimized
while true; do
    vmware-view --serverURL $server --useExisting --userName $ebiuser --password $ebipass --domainName $domain --nonInteractive --applicationName "$app" &
    sleep 5  # Wait for the application to start
    wmctrl -r "VMware Horizon Client" -b add,hidden
    wait \$!
done &
EOF

# Adjust ownership of the created files to the given user
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config/openbox

echo "Openbox autostart file created for $USERNAME at /home/$USERNAME/.config/openbox/autostart"


# Set the paths for the menu.xml and autostart.editor.py files
MENU_FILE="/home/$USERNAME/.config/openbox/menu.xml"
EDITOR_FILE="/home/$USERNAME/autostart.editor.py"

####################
# Write the menu.xml file
####################
cat << EOF > "$MENU_FILE"
<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openbox.org/
                file:///usr/share/openbox/menu.xsd">

<menu id="root-menu" label="Openbox 3">
  <item label="Terminal emulator">
    <action name="Execute"><execute>x-terminal-emulator</execute></action>
  </item>
  <item label="Web browser">
    <action name="Execute"><execute>x-www-browser</execute></action>
  </item>
  <!-- This requires the presence of the 'obamenu' package to work -->
  <menu id="/Debian" />
  <separator />
  <menu id="applications-menu" label="Applications" execute="/usr/bin/obamenu"/>
  <separator />
  
  <!-- Add your custom item here -->
  <item label="Autostart File Editor">
    <action name="Execute"><execute>python3 /home/$USERNAME/autostart.editor.py</execute></action>
  </item>
  
  <separator />
  <item label="ObConf">
    <action name="Execute"><execute>obconf</execute></action>
  </item>
  <item label="Reconfigure">
    <action name="Reconfigure" />
  </item>
  <item label="Restart">
    <action name="Restart" />
  </item>
  <separator />
  <item label="Exit">
    <action name="Exit" />
  </item>
</menu>

</openbox_menu>
EOF

# Set the correct ownership for menu.xml
chown -R "$USERNAME:$USERNAME" /home/$USERNAME/.config/openbox

echo "menu.xml has been created for $USERNAME at $MENU_FILE"

####################
# Write the autostart.editor.py file
####################
cat << EOF > "$EDITOR_FILE"
import tkinter as tk
from tkinter import messagebox
import os

# Path to the autostart file
AUTOSTART_FILE = "/home/$USERNAME/.config/openbox/autostart"

# Function to extract the value inside quotes (removing special characters)
def extract_value(line, param):
    start = line.find(param) + len(param) + 1  # +1 to handle the space after the parameter
    value = line[start:].strip().split()[0]  # Get the value, ignore anything after the first space
    if value.startswith('"') and value.endswith('"'):
        value = value[1:-1]  # Remove surrounding quotes if they exist
    return value

# Function to load values from the autostart file (if exists)
def load_autostart_file():
    try:
        with open(AUTOSTART_FILE, 'r') as f:
            lines = f.readlines()
            config_data = {
                'server': '',
                'ebiuser': '',
                'ebipass': '',
                'domain': '',
                'app': ''
            }
            # Parse the autostart file content
            for line in lines:
                if '--serverURL' in line:
                    config_data['server'] = extract_value(line, '--serverURL')
                if '--userName' in line:
                    config_data['ebiuser'] = extract_value(line, '--userName')
                if '--password' in line:
                    config_data['ebipass'] = extract_value(line, '--password')
                if '--domainName' in line:
                    config_data['domain'] = extract_value(line, '--domainName')
                if '--applicationName' in line:
                    config_data['app'] = extract_value(line, '--applicationName')
            return config_data
    except FileNotFoundError:
        # Return empty values if the autostart file doesn't exist
        return {'server': '', 'ebiuser': '', 'ebipass': '', 'domain': '', 'app': ''}
    except Exception as e:
        messagebox.showerror("Error", f"Error loading autostart file: {e}")
        return None

# Function to save values to the autostart file
def save_autostart_file(server, ebiuser, ebipass, domain, app):
    try:
        # Ensure the Openbox directory exists
        os.makedirs(os.path.dirname(AUTOSTART_FILE), exist_ok=True)

        # Write the new content to the autostart file
        with open(AUTOSTART_FILE, 'w') as f:
            f.write(f"# Disable DPMS and prevent screen blanking\n")
            f.write(f"xset -dpms s off s noblank s noexpose &\n\n")
            f.write(f"# Set background color\n")
            f.write(f"xsetroot -solid '#7393B3' &\n\n")
            f.write(f"# Loop to keep vmware-view running minimized\n")
            f.write(f"while true; do\n")
            f.write(f'    vmware-view --serverURL "{server}" --useExisting --userName "{ebiuser}" '
                    f'--password "{ebipass}" --domainName "{domain}" --nonInteractive --applicationName "{app}" &\n')
            f.write(f"    sleep 5  # Wait for the application to start\n")
            f.write(f"    wmctrl -r 'VMware Horizon Client' -b add,hidden\n")
            f.write(f"    wait $!\n")
            f.write(f"done &\n")
        messagebox.showinfo("Success", "Autostart file saved successfully!")
    except Exception as e:
        messagebox.showerror("Error", f"Failed to save autostart file: {e}")

# Tkinter window setup
root = tk.Tk()
root.title("Linux Horizon Client Configurator By AYNFT")

# Load the current values from the autostart file if it exists
config = load_autostart_file()

# Tkinter Labels and Entry fields for each parameter
tk.Label(root, text="Server URL:").grid(row=0, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Username:").grid(row=1, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Password:").grid(row=2, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Domain Name:").grid(row=3, column=0, padx=10, pady=5, sticky='e')
tk.Label(root, text="Application Name:").grid(row=4, column=0, padx=10, pady=5, sticky='e')

# Text fields for input
server_entry = tk.Entry(root, width=50)
ebiuser_entry = tk.Entry(root, width=50)
ebipass_entry = tk.Entry(root, show="*", width=50)  # Hide password
domain_entry = tk.Entry(root, width=50)
app_entry = tk.Entry(root, width=50)

# Pre-fill the entry fields with the current config values
if config:
    server_entry.insert(0, config.get('server', ''))
    ebiuser_entry.insert(0, config.get('ebiuser', ''))
    ebipass_entry.insert(0, config.get('ebipass', ''))
    domain_entry.insert(0, config.get('domain', ''))
    app_entry.insert(0, config.get('app', ''))

# Layout the entry fields
server_entry.grid(row=0, column=1, padx=10, pady=5)
ebiuser_entry.grid(row=1, column=1, padx=10, pady=5)
ebipass_entry.grid(row=2, column=1, padx=10, pady=5)
domain_entry.grid(row=3, column=1, padx=10, pady=5)
app_entry.grid(row=4, column=1, padx=10, pady=5)

# Save button function to write to autostart file
def on_save():
    server = server_entry.get()
    ebiuser = ebiuser_entry.get()
    ebipass = ebipass_entry.get()
    domain = domain_entry.get()
    app = app_entry.get()

    # Save the updated configuration to the autostart file
    save_autostart_file(server, ebiuser, ebipass, domain, app)

# Save Button
save_button = tk.Button(root, text="Save", command=on_save)
save_button.grid(row=5, column=1, pady=20)

root.mainloop()
EOF

# Set the correct ownership for autostart.editor.py
chown "$USERNAME:$USERNAME" "$EDITOR_FILE"

echo "autostart.editor.py has been created for $USERNAME at $EDITOR_FILE"














