set -e
# replaceing "#autologin-user=" to "autologin-user=live"
sed -i -e 's/#autologin-user=/autologin-user=live/g' /etc/lightdm/lightdm.conf

# replaceing "#autologin-user-timeout=0" to "autologin-user-timeout=0"
sed -i -e 's/#autologin-user-timeout=0/autologin-user-timeout=0/g' /etc/lightdm/lightdm.conf