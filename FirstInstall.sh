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
apt install python3-tk


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









