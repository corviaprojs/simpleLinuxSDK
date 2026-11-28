set -e

# creating user
adduser live --disabled-password --gecos "" || true

# setting it here for esier understanding/visiblity

#dont use that in a production! :Đ
root_passwd="root"
user_passwd="live"

# setting 'root' password with pipeing
echo "root:$root_passwd" | chpasswd
echo "live:$user_passwd" | chpasswd

usermod -aG sudo live 